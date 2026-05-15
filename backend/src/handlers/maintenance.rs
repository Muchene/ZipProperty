use axum::{routing::get, Router};

pub fn routes() -> Router {
    Router::new()
        .route("/", get(list_maintenance_requests))
        .route("/:id", get(get_maintenance_request))
}

async fn list_maintenance_requests() -> &'static str {
    "Maintenance requests endpoint - TODO: Implement"
}

async fn get_maintenance_request() -> &'static str {
    "Get maintenance request endpoint - TODO: Implement"
}
