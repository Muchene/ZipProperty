use axum::{
    extract::Extension,
    http::StatusCode,
    response::Json,
    routing::{get, post},
    Router,
};
use sqlx::PgPool;
use std::net::SocketAddr;
use tower::ServiceBuilder;
use tower_http::{cors::CorsLayer, trace::TraceLayer};
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

mod config;
mod database;
mod error;
mod handlers;
mod middleware;
mod models;
mod repositories;
mod services;

use config::Config;
use error::AppError;

#[derive(OpenApi)]
#[openapi(
    paths(
        handlers::health::health_check,
        handlers::auth::login,
        handlers::auth::register,
    ),
    components(
        schemas(models::auth::LoginRequest, models::auth::RegisterRequest, models::auth::AuthResponse)
    ),
    tags(
        (name = "health", description = "Health check endpoints"),
        (name = "auth", description = "Authentication endpoints"),
        (name = "properties", description = "Property management endpoints"),
        (name = "tenants", description = "Tenant management endpoints"),
        (name = "payments", description = "Payment management endpoints"),
        (name = "maintenance", description = "Maintenance request endpoints"),
    )
)]
struct ApiDoc;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    // Initialize tracing
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "zipproperty_backend=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load configuration
    let config = Config::from_env()?;

    // Initialize database
    let pool = database::init_pool(&config.database_url).await?;
    database::run_migrations(&pool).await?;

    // Build our application with routes
    let app = Router::new()
        .route("/api/health", get(handlers::health::health_check))
        .route("/api/auth/login", post(handlers::auth::login))
        .route("/api/auth/register", post(handlers::auth::register))
        .nest("/api/properties", handlers::properties::routes())
        .nest("/api/tenants", handlers::tenants::routes())
        .nest("/api/payments", handlers::payments::routes())
        .nest("/api/maintenance", handlers::maintenance::routes())
        .merge(SwaggerUi::new("/api/docs").url("/api-docs/openapi.json", ApiDoc::openapi()))
        .layer(
            ServiceBuilder::new()
                .layer(TraceLayer::new_for_http())
                .layer(CorsLayer::permissive())
                .layer(Extension(pool))
                .layer(Extension(config)),
        );

    // Run the server
    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    tracing::info!("Server listening on {}", addr);
    
    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
