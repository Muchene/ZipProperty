use axum::{
    extract::Extension,
    http::StatusCode,
    response::Json,
};
use sqlx::PgPool;
use sqlx::Row;
use validator::Validate;

use crate::{
    config::Config,
    error::AppError,
    models::auth::{AcceptInviteRequest, AuthResponse, LoginRequest, RegisterRequest, UserInfo, UserRole},
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
    Extension(config): Extension<Config>,
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
    let token = generate_jwt_token(&user, &config.jwt_secret)?;

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
    Extension(config): Extension<Config>,
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
    .bind(UserRole::Member)
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
    let token = generate_jwt_token(&user, &config.jwt_secret)?;

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

#[utoipa::path(
    post,
    path = "/api/auth/invites/accept",
    tag = "auth",
    request_body = AcceptInviteRequest,
    responses(
        (status = 200, description = "Invite accepted", body = AuthResponse),
        (status = 400, description = "Invalid input"),
        (status = 404, description = "Invite not found"),
        (status = 409, description = "Invite is no longer valid")
    )
)]
pub async fn accept_invite(
    Extension(pool): Extension<PgPool>,
    Extension(config): Extension<Config>,
    Json(payload): Json<AcceptInviteRequest>,
) -> Result<Json<AuthResponse>, AppError> {
    payload.validate().map_err(|e| AppError::Validation(e.to_string()))?;

    let invite_row = sqlx::query(
        r#"
        SELECT id, email, name, property_id, invite_type::text AS invite_type,
               invited_user_id, status::text AS status, expires_at
        FROM user_invites
        WHERE token = $1
        LIMIT 1
        "#,
    )
    .bind(&payload.token)
    .fetch_optional(&pool)
    .await?
    .ok_or_else(|| AppError::NotFound("Invite not found".to_string()))?;

    let invite_id: uuid::Uuid = invite_row.try_get("id")?;
    let email: String = invite_row.try_get("email")?;
    let invite_name: Option<String> = invite_row.try_get("name")?;
    let property_id: uuid::Uuid = invite_row.try_get("property_id")?;
    let invite_type: String = invite_row.try_get("invite_type")?;
    let invited_user_id: Option<uuid::Uuid> = invite_row.try_get("invited_user_id")?;
    let status: String = invite_row.try_get("status")?;
    let expires_at: chrono::DateTime<chrono::Utc> = invite_row.try_get("expires_at")?;

    if status != "pending" {
        return Err(AppError::Conflict("Invite is no longer pending".to_string()));
    }

    if expires_at < chrono::Utc::now() {
        sqlx::query("UPDATE user_invites SET status = 'expired', updated_at = NOW() WHERE id = $1")
            .bind(invite_id)
            .execute(&pool)
            .await?;
        return Err(AppError::Conflict("Invite has expired".to_string()));
    }

    let user_id = if let Some(user_id) = invited_user_id {
        user_id
    } else {
        let existing_user_id: Option<uuid::Uuid> =
            sqlx::query_scalar("SELECT id FROM users WHERE email = $1")
                .bind(&email)
                .fetch_optional(&pool)
                .await?;

        if let Some(user_id) = existing_user_id {
            user_id
        } else {
            let new_user_id = uuid::Uuid::new_v4();
            let generated_name = payload
                .name
                .clone()
                .or(invite_name.clone())
                .unwrap_or_else(|| email.split('@').next().unwrap_or("User").to_string());
            let password_hash = bcrypt::hash(uuid::Uuid::new_v4().to_string(), bcrypt::DEFAULT_COST)
                .map_err(|_| AppError::Internal("Failed to create invited user".to_string()))?;

            sqlx::query(
                r#"
                INSERT INTO users (id, name, email, password_hash, role, created_at, updated_at)
                VALUES ($1, $2, $3, $4, 'member', NOW(), NOW())
                "#,
            )
            .bind(new_user_id)
            .bind(generated_name)
            .bind(&email)
            .bind(password_hash)
            .execute(&pool)
            .await?;

            new_user_id
        }
    };

    let password_hash = bcrypt::hash(&payload.password, bcrypt::DEFAULT_COST)
        .map_err(|_| AppError::Internal("Failed to hash password".to_string()))?;

    let new_name = payload
        .name
        .clone()
        .or(invite_name)
        .unwrap_or_else(|| email.split('@').next().unwrap_or("User").to_string());

    let role = if invite_type == "agent" {
        UserRole::Agent
    } else {
        UserRole::Tenant
    };

    sqlx::query(
        "UPDATE users SET password_hash = $1, name = $2, role = $3, updated_at = NOW() WHERE id = $4",
    )
    .bind(password_hash)
    .bind(new_name)
    .bind(role)
    .bind(user_id)
    .execute(&pool)
    .await?;

    if invite_type == "agent" {
        sqlx::query(
            "UPDATE property_agents SET status = 'active', updated_at = NOW() WHERE property_id = $1 AND user_id = $2",
        )
        .bind(property_id)
        .bind(user_id)
        .execute(&pool)
        .await?;
    } else {
        sqlx::query(
            "UPDATE tenants SET status = 'active', updated_at = NOW() WHERE property_id = $1 AND user_id = $2",
        )
        .bind(property_id)
        .bind(user_id)
        .execute(&pool)
        .await?;
    }

    sqlx::query(
        "UPDATE user_invites SET invited_user_id = $1, status = 'accepted', accepted_at = NOW(), updated_at = NOW() WHERE id = $2",
    )
    .bind(user_id)
    .bind(invite_id)
    .execute(&pool)
    .await?;

    let user = sqlx::query_as::<_, User>(
        "SELECT id, name, email, password_hash, role, created_at, updated_at FROM users WHERE id = $1",
    )
    .bind(user_id)
    .fetch_one(&pool)
    .await?;

    let token = generate_jwt_token(&user, &config.jwt_secret)?;

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

fn generate_jwt_token(user: &User, secret: &str) -> Result<String, AppError> {
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
        &EncodingKey::from_secret(secret.as_ref()),
    )
    .map_err(|_| AppError::Internal("Failed to generate token".to_string()))?;

    Ok(token)
}
