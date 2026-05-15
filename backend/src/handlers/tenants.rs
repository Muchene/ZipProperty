use axum::{routing::get, Router};

pub fn routes() -> Router {
    Router::new()
        .route("/", get(list_tenants))
        .route("/:id", get(get_tenant))
}

async fn list_tenants() -> &'static str {
    "Tenants endpoint - TODO: Implement"
}

async fn get_tenant() -> &'static str {
    "Get tenant endpoint - TODO: Implement"
}
