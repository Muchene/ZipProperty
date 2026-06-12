use axum::{routing::get, Router};

pub fn routes() -> Router {
    Router::new()
        .route("/", get(list_payments))
        .route("/:id", get(get_payment))
}

async fn list_payments() -> &'static str {
    "Payments endpoint - TODO: Implement"
}

async fn get_payment() -> &'static str {
    "Get payment endpoint - TODO: Implement"
}
