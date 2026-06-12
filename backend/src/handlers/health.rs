use axum::{http::StatusCode, response::Json};
use serde_json::{json, Value};

#[utoipa::path(
    get,
    path = "/api/health",
    tag = "health",
    responses(
        (status = 200, description = "Health check successful", body = Value)
    )
)]
pub async fn health_check() -> Result<Json<Value>, StatusCode> {
    Ok(Json(json!({
        "status": "healthy",
        "timestamp": chrono::Utc::now(),
        "service": "ZipProperty Backend"
    })))
}
