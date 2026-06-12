use axum::{
    extract::{Extension, Path},
    http::{HeaderMap, StatusCode},
    response::Json,
    routing::{get, post},
    Router,
};
use sqlx::{postgres::PgRow, PgPool, Row};

use crate::{
    config::Config,
    error::AppError,
    handlers::auth_utils::extract_user_id,
    models::{
        auth::UserRole,
        tenant::{AssignTenantRequest, AssignTenantResponse, TenantResponse},
        user::User,
    },
};

pub fn routes() -> Router {
    Router::new()
        .route("/", get(list_tenants))
        .route("/assign", post(assign_tenant))
        .route("/:id", get(get_tenant))
}

pub async fn list_tenants(
    Extension(pool): Extension<PgPool>,
    Extension(config): Extension<Config>,
    headers: HeaderMap,
) -> Result<Json<Vec<TenantResponse>>, AppError> {
    let user_id = extract_user_id(&headers, &config)?;

    let rows = sqlx::query(
        r#"
        SELECT DISTINCT t.id, t.user_id, t.property_id, t.unit_number,
               t.lease_start_date, t.lease_end_date,
               t.monthly_rent::double precision AS monthly_rent,
               t.security_deposit::double precision AS security_deposit,
               t.status, t.emergency_contact_name,
               t.emergency_contact_phone, t.created_at, t.updated_at
        FROM tenants t
        JOIN properties p ON p.id = t.property_id
        LEFT JOIN property_agents pa ON pa.property_id = p.id
        WHERE p.owner_id = $1 OR (pa.user_id = $1 AND pa.status = 'active')
        ORDER BY t.created_at DESC
        "#,
    )
    .bind(user_id)
    .fetch_all(&pool)
    .await?;

    let tenants = rows
        .iter()
        .map(row_to_tenant_response)
        .collect::<Result<Vec<_>, _>>()?;

    Ok(Json(tenants))
}

pub async fn get_tenant(
    Extension(pool): Extension<PgPool>,
    Extension(config): Extension<Config>,
    headers: HeaderMap,
    Path(tenant_id): Path<uuid::Uuid>,
) -> Result<Json<TenantResponse>, AppError> {
    let user_id = extract_user_id(&headers, &config)?;

    let row = sqlx::query(
        r#"
        SELECT t.id, t.user_id, t.property_id, t.unit_number,
               t.lease_start_date, t.lease_end_date,
               t.monthly_rent::double precision AS monthly_rent,
               t.security_deposit::double precision AS security_deposit,
               t.status, t.emergency_contact_name,
               t.emergency_contact_phone, t.created_at, t.updated_at
        FROM tenants t
        JOIN properties p ON p.id = t.property_id
        LEFT JOIN property_agents pa ON pa.property_id = p.id
        WHERE t.id = $1 AND (p.owner_id = $2 OR (pa.user_id = $2 AND pa.status = 'active'))
        LIMIT 1
        "#,
    )
    .bind(tenant_id)
    .bind(user_id)
    .fetch_optional(&pool)
    .await?
    .ok_or_else(|| AppError::NotFound("Tenant not found".to_string()))?;

    Ok(Json(row_to_tenant_response(&row)?))
}

pub async fn assign_tenant(
    Extension(pool): Extension<PgPool>,
    Extension(config): Extension<Config>,
    headers: HeaderMap,
    Json(payload): Json<AssignTenantRequest>,
) -> Result<(StatusCode, Json<AssignTenantResponse>), AppError> {
    let actor_id = extract_user_id(&headers, &config)?;

    let owner_id: uuid::Uuid = sqlx::query_scalar("SELECT owner_id FROM properties WHERE id = $1")
        .bind(payload.property_id)
        .fetch_optional(&pool)
        .await?
        .ok_or_else(|| AppError::NotFound("Property not found".to_string()))?;

    let actor_is_owner = owner_id == actor_id;
    let actor_is_active_agent: bool = sqlx::query_scalar(
        "SELECT EXISTS(SELECT 1 FROM property_agents WHERE property_id = $1 AND user_id = $2 AND status = 'active')",
    )
    .bind(payload.property_id)
    .bind(actor_id)
    .fetch_one(&pool)
    .await?;

    if !actor_is_owner && !actor_is_active_agent {
        return Err(AppError::Authorization(
            "Only owner or assigned agent can assign tenants".to_string(),
        ));
    }

    let existing_user = sqlx::query_as::<_, User>(
        "SELECT id, name, email, password_hash, role, created_at, updated_at FROM users WHERE email = $1",
    )
    .bind(&payload.email)
    .fetch_optional(&pool)
    .await?;

    let (tenant_user_id, invite_sent) = if let Some(user) = existing_user {
        (user.id, false)
    } else {
        let user_id = uuid::Uuid::new_v4();
        let generated_name = payload
            .name
            .clone()
            .unwrap_or_else(|| payload.email.split('@').next().unwrap_or("Tenant").to_string());
        let temp_secret = uuid::Uuid::new_v4().to_string();
        let password_hash = bcrypt::hash(temp_secret, bcrypt::DEFAULT_COST)
            .map_err(|_| AppError::Internal("Failed to prepare invited tenant".to_string()))?;

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

    let tenant_id = uuid::Uuid::new_v4();
    let tenant_status = if invite_sent { "pending" } else { "active" };

    sqlx::query(
        r#"
        INSERT INTO tenants (
            id, user_id, property_id, unit_number, lease_start_date, lease_end_date,
            monthly_rent, security_deposit, status, emergency_contact_name,
            emergency_contact_phone, created_at, updated_at
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7::numeric, $8::numeric, $9::tenant_status, $10, $11, NOW(), NOW())
        ON CONFLICT (user_id, property_id)
        DO UPDATE SET
            unit_number = EXCLUDED.unit_number,
            lease_start_date = EXCLUDED.lease_start_date,
            lease_end_date = EXCLUDED.lease_end_date,
            monthly_rent = EXCLUDED.monthly_rent,
            security_deposit = EXCLUDED.security_deposit,
            status = EXCLUDED.status,
            emergency_contact_name = EXCLUDED.emergency_contact_name,
            emergency_contact_phone = EXCLUDED.emergency_contact_phone,
            updated_at = NOW()
        RETURNING id
        "#,
    )
    .bind(tenant_id)
    .bind(tenant_user_id)
    .bind(payload.property_id)
    .bind(&payload.unit_number)
    .bind(payload.lease_start_date)
    .bind(payload.lease_end_date)
    .bind(payload.monthly_rent)
    .bind(payload.security_deposit)
    .bind(tenant_status)
    .bind(&payload.emergency_contact_name)
    .bind(&payload.emergency_contact_phone)
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
            VALUES ($1, $2, $3, 'tenant', $4, $5, $6, 'pending', NOW() + INTERVAL '7 days', NOW(), NOW())
            "#,
        )
        .bind(&payload.email)
        .bind(&payload.name)
        .bind(payload.property_id)
        .bind(actor_id)
        .bind(tenant_user_id)
        .bind(&token)
        .execute(&pool)
        .await?;

        tracing::info!(
            "Invite stub for tenant email={} property_id={} token={}",
            payload.email,
            payload.property_id,
            token
        );
    }

    let assigned_tenant_id: uuid::Uuid = sqlx::query_scalar(
        "SELECT id FROM tenants WHERE user_id = $1 AND property_id = $2",
    )
    .bind(tenant_user_id)
    .bind(payload.property_id)
    .fetch_one(&pool)
    .await?;

    Ok((
        StatusCode::CREATED,
        Json(AssignTenantResponse {
            tenant_id: assigned_tenant_id,
            user_id: tenant_user_id,
            property_id: payload.property_id,
            invite_sent,
        }),
    ))
}

fn row_to_tenant_response(row: &PgRow) -> Result<TenantResponse, sqlx::Error> {
    Ok(TenantResponse {
        id: row.try_get("id")?,
        user_id: row.try_get("user_id")?,
        property_id: row.try_get("property_id")?,
        unit_number: row.try_get("unit_number")?,
        lease_start_date: row.try_get("lease_start_date")?,
        lease_end_date: row.try_get("lease_end_date")?,
        monthly_rent: row.try_get("monthly_rent")?,
        security_deposit: row.try_get("security_deposit")?,
        status: row.try_get("status")?,
        emergency_contact_name: row.try_get("emergency_contact_name")?,
        emergency_contact_phone: row.try_get("emergency_contact_phone")?,
        created_at: row.try_get("created_at")?,
        updated_at: row.try_get("updated_at")?,
    })
}
