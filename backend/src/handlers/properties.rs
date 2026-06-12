use axum::{
    extract::{Extension, Path},
    http::{HeaderMap, StatusCode},
    response::Json,
    routing::{get, post},
    Router,
};
use sqlx::PgPool;

use crate::{
    config::Config,
    error::AppError,
    handlers::auth_utils::extract_user_id,
    models::{
        auth::UserRole,
        property::{
            AssignAgentRequest, AssignAgentResponse, CreatePropertyRequest, Property, PropertyResponse,
        },
        user::User,
    },
};

pub fn routes() -> Router {
    Router::new()
        .route("/", get(list_properties).post(create_property))
        .route("/:id", get(get_property))
        .route("/:id/agents", post(assign_agent))
}

pub async fn list_properties(
    Extension(pool): Extension<PgPool>,
    Extension(config): Extension<Config>,
    headers: HeaderMap,
) -> Result<Json<Vec<PropertyResponse>>, AppError> {
    let user_id = extract_user_id(&headers, &config)?;

    let properties = sqlx::query_as::<_, Property>(
        r#"
        SELECT DISTINCT p.id, p.owner_id, p.agent_id, p.name, p.address, p.city, p.state,
               p.zip_code, p.country, p.property_type, p.total_units, p.description,
               p.created_at, p.updated_at
        FROM properties p
        LEFT JOIN property_agents pa ON pa.property_id = p.id
        WHERE p.owner_id = $1 OR (pa.user_id = $1 AND pa.status = 'active')
        ORDER BY p.created_at DESC
        "#,
    )
    .bind(user_id)
    .fetch_all(&pool)
    .await?;

    Ok(Json(properties.into_iter().map(to_response).collect()))
}

pub async fn get_property(
    Extension(pool): Extension<PgPool>,
    Extension(config): Extension<Config>,
    headers: HeaderMap,
    Path(property_id): Path<uuid::Uuid>,
) -> Result<Json<PropertyResponse>, AppError> {
    let user_id = extract_user_id(&headers, &config)?;

    let property = sqlx::query_as::<_, Property>(
        r#"
        SELECT p.id, p.owner_id, p.agent_id, p.name, p.address, p.city, p.state,
               p.zip_code, p.country, p.property_type, p.total_units, p.description,
               p.created_at, p.updated_at
        FROM properties p
        LEFT JOIN property_agents pa ON pa.property_id = p.id
        WHERE p.id = $1 AND (p.owner_id = $2 OR (pa.user_id = $2 AND pa.status = 'active'))
        LIMIT 1
        "#,
    )
    .bind(property_id)
    .bind(user_id)
    .fetch_optional(&pool)
    .await?
    .ok_or_else(|| AppError::NotFound("Property not found".to_string()))?;

    Ok(Json(to_response(property)))
}

pub async fn create_property(
    Extension(pool): Extension<PgPool>,
    Extension(config): Extension<Config>,
    headers: HeaderMap,
    Json(payload): Json<CreatePropertyRequest>,
) -> Result<(StatusCode, Json<PropertyResponse>), AppError> {
    let user_id = extract_user_id(&headers, &config)?;
    let property_id = uuid::Uuid::new_v4();

    sqlx::query(
        r#"
        INSERT INTO properties (
            id, owner_id, name, address, city, state, zip_code, country,
            property_type, total_units, description, created_at, updated_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW(), NOW())
        "#,
    )
    .bind(property_id)
    .bind(user_id)
    .bind(&payload.name)
    .bind(&payload.address)
    .bind(&payload.city)
    .bind(&payload.state)
    .bind(&payload.zip_code)
    .bind(&payload.country)
    .bind(&payload.property_type)
    .bind(payload.total_units)
    .bind(&payload.description)
    .execute(&pool)
    .await?;

    // Creating a property promotes a neutral member account to owner.
    sqlx::query("UPDATE users SET role = 'owner' WHERE id = $1 AND role = 'member'")
        .bind(user_id)
        .execute(&pool)
        .await?;

    let property = sqlx::query_as::<_, Property>(
        r#"
        SELECT id, owner_id, agent_id, name, address, city, state,
               zip_code, country, property_type, total_units, description,
               created_at, updated_at
        FROM properties
        WHERE id = $1
        "#,
    )
    .bind(property_id)
    .fetch_one(&pool)
    .await?;

    Ok((StatusCode::CREATED, Json(to_response(property))))
}

pub async fn assign_agent(
    Extension(pool): Extension<PgPool>,
    Extension(config): Extension<Config>,
    headers: HeaderMap,
    Path(property_id): Path<uuid::Uuid>,
    Json(payload): Json<AssignAgentRequest>,
) -> Result<(StatusCode, Json<AssignAgentResponse>), AppError> {
    let actor_id = extract_user_id(&headers, &config)?;

    let owner_id: uuid::Uuid = sqlx::query_scalar("SELECT owner_id FROM properties WHERE id = $1")
        .bind(property_id)
        .fetch_optional(&pool)
        .await?
        .ok_or_else(|| AppError::NotFound("Property not found".to_string()))?;

    if owner_id != actor_id {
        return Err(AppError::Authorization(
            "Only property owner can assign an agent".to_string(),
        ));
    }

    let existing_user = sqlx::query_as::<_, User>(
        "SELECT id, name, email, password_hash, role, created_at, updated_at FROM users WHERE email = $1",
    )
    .bind(&payload.email)
    .fetch_optional(&pool)
    .await?;

    let (agent_user_id, invite_sent) = if let Some(user) = existing_user {
        (user.id, false)
    } else {
        let user_id = uuid::Uuid::new_v4();
        let generated_name = payload
            .name
            .clone()
            .unwrap_or_else(|| payload.email.split('@').next().unwrap_or("Agent").to_string());
        let temp_secret = uuid::Uuid::new_v4().to_string();
        let password_hash = bcrypt::hash(temp_secret, bcrypt::DEFAULT_COST)
            .map_err(|_| AppError::Internal("Failed to prepare invited agent".to_string()))?;

        sqlx::query(
            r#"
            INSERT INTO users (id, name, email, password_hash, role, created_at, updated_at)
            VALUES ($1, $2, $3, $4, $5, NOW(), NOW())
            "#,
        )
        .bind(user_id)
        .bind(generated_name)
        .bind(&payload.email)
        .bind(password_hash)
        .bind(UserRole::Member)
        .execute(&pool)
        .await?;

        (user_id, true)
    };

    let relation_status = if invite_sent { "pending" } else { "active" };
    sqlx::query(
        r#"
        INSERT INTO property_agents (property_id, user_id, status, created_at, updated_at)
        VALUES ($1, $2, $3::assignment_status, NOW(), NOW())
        ON CONFLICT (property_id, user_id)
        DO UPDATE SET status = EXCLUDED.status, updated_at = NOW()
        "#,
    )
    .bind(property_id)
    .bind(agent_user_id)
    .bind(relation_status)
    .execute(&pool)
    .await?;

    if invite_sent {
        let token = uuid::Uuid::new_v4().to_string();
        sqlx::query(
            r#"
            INSERT INTO user_invites (
                email, name, property_id, invite_type, invited_by, invited_user_id,
                token, status, expires_at, created_at, updated_at
            )
            VALUES ($1, $2, $3, 'agent', $4, $5, $6, 'pending', NOW() + INTERVAL '7 days', NOW(), NOW())
            "#,
        )
        .bind(&payload.email)
        .bind(&payload.name)
        .bind(property_id)
        .bind(actor_id)
        .bind(agent_user_id)
        .bind(&token)
        .execute(&pool)
        .await?;

        tracing::info!(
            "Invite stub for agent email={} property_id={} token={}",
            payload.email,
            property_id,
            token
        );
    }

    Ok((
        StatusCode::CREATED,
        Json(AssignAgentResponse {
            property_id,
            user_id: agent_user_id,
            invite_sent,
        }),
    ))
}

fn to_response(property: Property) -> PropertyResponse {
    PropertyResponse {
        id: property.id,
        owner_id: property.owner_id,
        agent_id: property.agent_id,
        name: property.name,
        address: property.address,
        city: property.city,
        state: property.state,
        zip_code: property.zip_code,
        country: property.country,
        property_type: property.property_type,
        total_units: property.total_units,
        description: property.description,
        created_at: property.created_at,
        updated_at: property.updated_at,
    }
}
