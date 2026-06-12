use axum::{
    extract::Extension,
    http::HeaderMap,
    response::Json,
    routing::get,
    Router,
};
use serde::Serialize;
use sqlx::PgPool;

use crate::{
    config::Config,
    error::AppError,
    handlers::auth_utils::extract_user_id,
};

pub fn routes() -> Router {
    Router::new().route("/summary", get(get_billing_summary))
}

#[derive(Debug, Serialize)]
pub struct BillingSummaryResponse {
    pub owner_id: uuid::Uuid,
    pub billable_users: i64,
    pub active_agents: i64,
    pub active_tenants: i64,
}

pub async fn get_billing_summary(
    Extension(pool): Extension<PgPool>,
    Extension(config): Extension<Config>,
    headers: HeaderMap,
) -> Result<Json<BillingSummaryResponse>, AppError> {
    let owner_id = extract_user_id(&headers, &config)?;

    let active_agents: i64 = sqlx::query_scalar(
        r#"
        SELECT COUNT(DISTINCT pa.user_id)
        FROM properties p
        JOIN property_agents pa ON pa.property_id = p.id
        WHERE p.owner_id = $1
          AND pa.status = 'active'
        "#,
    )
    .bind(owner_id)
    .fetch_one(&pool)
    .await?;

    let active_tenants: i64 = sqlx::query_scalar(
        r#"
        SELECT COUNT(DISTINCT t.user_id)
        FROM properties p
        JOIN tenants t ON t.property_id = p.id
        WHERE p.owner_id = $1
          AND t.status = 'active'
        "#,
    )
    .bind(owner_id)
    .fetch_one(&pool)
    .await?;

    let billable_users: i64 = sqlx::query_scalar(
        r#"
        SELECT COUNT(DISTINCT attached.user_id)
        FROM (
            SELECT pa.user_id
            FROM properties p
            JOIN property_agents pa ON pa.property_id = p.id
            WHERE p.owner_id = $1
              AND pa.status = 'active'
            UNION
            SELECT t.user_id
            FROM properties p
            JOIN tenants t ON t.property_id = p.id
            WHERE p.owner_id = $1
              AND t.status = 'active'
        ) AS attached
        "#,
    )
    .bind(owner_id)
    .fetch_one(&pool)
    .await?;

    Ok(Json(BillingSummaryResponse {
        owner_id,
        billable_users,
        active_agents,
        active_tenants,
    }))
}
