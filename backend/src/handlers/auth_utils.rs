use axum::http::{header::AUTHORIZATION, HeaderMap};
use jsonwebtoken::{decode, DecodingKey, Validation};
use serde::Deserialize;
use uuid::Uuid;

use crate::{config::Config, error::AppError};

#[derive(Debug, Deserialize)]
struct Claims {
    sub: String,
    exp: usize,
}

pub fn extract_user_id(headers: &HeaderMap, config: &Config) -> Result<Uuid, AppError> {
    let auth_header = headers
        .get(AUTHORIZATION)
        .ok_or_else(|| AppError::Authentication("Missing authorization header".to_string()))?
        .to_str()
        .map_err(|_| AppError::Authentication("Invalid authorization header".to_string()))?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .ok_or_else(|| AppError::Authentication("Invalid bearer token".to_string()))?;

    let claims = decode::<Claims>(
        token,
        &DecodingKey::from_secret(config.jwt_secret.as_ref()),
        &Validation::default(),
    )
    .map_err(|_| AppError::Authentication("Invalid or expired token".to_string()))?
    .claims;

    Uuid::parse_str(&claims.sub)
        .map_err(|_| AppError::Authentication("Invalid token subject".to_string()))
}
