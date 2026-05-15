use axum::{
    extract::Extension,
    http::StatusCode,
    response::Json,
};
use sqlx::PgPool;
use validator::Validate;

use crate::{
    error::AppError,
    models::auth::{AuthResponse, LoginRequest, RegisterRequest, UserInfo, UserRole},
    models::user::User,
};

#[utoipa::path(
    post,
    path = "/api/auth/login",
    tag = "auth",
    request_body = LoginRequest,
    responses(
        (status = 200, description = "Login successful", body = AuthResponse),
        (status = 400, description = "Invalid credentials"),
        (status = 401, description = "Unauthorized")
    )
)]
pub async fn login(
    Extension(pool): Extension<PgPool>,
    Json(payload): Json<LoginRequest>,
) -> Result<Json<AuthResponse>, AppError> {
    // Validate input
    payload.validate().map_err(|e| AppError::Validation(e.to_string()))?;

    // Find user by email
    let user = sqlx::query_as::<_, User>(
        "SELECT id, name, email, password_hash, role, created_at, updated_at FROM users WHERE email = $1"
    )
    .bind(&payload.email)
    .fetch_optional(&pool)
    .await?
    .ok_or_else(|| AppError::Authentication("Invalid credentials".to_string()))?;

    // Verify password
    let is_valid = bcrypt::verify(&payload.password, &user.password_hash)
        .map_err(|_| AppError::Authentication("Invalid credentials".to_string()))?;

    if !is_valid {
        return Err(AppError::Authentication("Invalid credentials".to_string()));
    }

    // Generate JWT token
    let token = generate_jwt_token(&user)?;

    Ok(Json(AuthResponse {
        token,
        user: UserInfo {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
        },
    }))
}

#[utoipa::path(
    post,
    path = "/api/auth/register",
    tag = "auth",
    request_body = RegisterRequest,
    responses(
        (status = 201, description = "Registration successful", body = AuthResponse),
        (status = 400, description = "Invalid input"),
        (status = 409, description = "User already exists")
    )
)]
pub async fn register(
    Extension(pool): Extension<PgPool>,
    Json(payload): Json<RegisterRequest>,
) -> Result<(StatusCode, Json<AuthResponse>), AppError> {
    // Validate input
    payload.validate().map_err(|e| AppError::Validation(e.to_string()))?;

    // Check if user already exists
    let existing_user = sqlx::query("SELECT id FROM users WHERE email = $1")
        .bind(&payload.email)
        .fetch_optional(&pool)
        .await?;

    if existing_user.is_some() {
        return Err(AppError::Conflict("User already exists".to_string()));
    }

    // Hash password
    let password_hash = bcrypt::hash(&payload.password, bcrypt::DEFAULT_COST)
        .map_err(|_| AppError::Internal("Failed to hash password".to_string()))?;

    // Create user
    let user_id = uuid::Uuid::new_v4();
    sqlx::query(
        r#"
        INSERT INTO users (id, name, email, password_hash, role, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, NOW(), NOW())
        "#
    )
    .bind(user_id)
    .bind(&payload.name)
    .bind(&payload.email)
    .bind(&password_hash)
    .bind(&payload.role)
    .execute(&pool)
    .await?;

    // Fetch the created user
    let user = sqlx::query_as::<_, User>(
        "SELECT id, name, email, password_hash, role, created_at, updated_at FROM users WHERE id = $1"
    )
    .bind(user_id)
    .fetch_one(&pool)
    .await?;

    // Generate JWT token
    let token = generate_jwt_token(&user)?;

    Ok((StatusCode::CREATED, Json(AuthResponse {
        token,
        user: UserInfo {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
        },
    })))
}

fn generate_jwt_token(user: &User) -> Result<String, AppError> {
    use jsonwebtoken::{encode, EncodingKey, Header};
    use serde::{Deserialize, Serialize};

    #[derive(Debug, Serialize, Deserialize)]
    struct Claims {
        sub: String,
        role: UserRole,
        exp: usize,
    }

    let expiration = chrono::Utc::now()
        .checked_add_signed(chrono::Duration::days(7))
        .expect("valid timestamp")
        .timestamp();

    let claims = Claims {
        sub: user.id.to_string(),
        role: user.role.clone(),
        exp: expiration as usize,
    };

    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret("your-secret-key-change-in-production".as_ref()),
    )
    .map_err(|_| AppError::Internal("Failed to generate token".to_string()))?;

    Ok(token)
}
