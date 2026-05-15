use axum::{routing::get, Router};

pub fn routes() -> Router {
    Router::new()
        .route("/", get(list_properties))
        .route("/:id", get(get_property))
}

async fn list_properties() -> &'static str {
    "Properties endpoint - TODO: Implement"
}

async fn get_property() -> &'static str {
    "Get property endpoint - TODO: Implement"
}
