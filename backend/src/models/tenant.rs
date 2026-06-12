use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;
use bigdecimal::BigDecimal;

#[derive(Debug, Serialize, Deserialize, ToSchema, sqlx::FromRow)]
pub struct Tenant {
    pub id: Uuid,
    pub user_id: Uuid,
    pub property_id: Uuid,
    pub unit_number: Option<String>,
    pub lease_start_date: DateTime<Utc>,
    pub lease_end_date: DateTime<Utc>,
    pub monthly_rent: BigDecimal,
    pub security_deposit: BigDecimal,
    pub status: TenantStatus,
    pub emergency_contact_name: Option<String>,
    pub emergency_contact_phone: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[sqlx(type_name = "tenant_status", rename_all = "lowercase")]
pub enum TenantStatus {
    Active,
    Inactive,
    Pending,
    Terminated,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct CreateTenantRequest {
    pub user_id: Uuid,
    pub property_id: Uuid,
    pub unit_number: Option<String>,
    pub lease_start_date: DateTime<Utc>,
    pub lease_end_date: DateTime<Utc>,
    pub monthly_rent: f64,
    pub security_deposit: f64,
    pub emergency_contact_name: Option<String>,
    pub emergency_contact_phone: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct UpdateTenantRequest {
    pub unit_number: Option<String>,
    pub lease_start_date: Option<DateTime<Utc>>,
    pub lease_end_date: Option<DateTime<Utc>>,
    pub monthly_rent: Option<f64>,
    pub security_deposit: Option<f64>,
    pub status: Option<TenantStatus>,
    pub emergency_contact_name: Option<String>,
    pub emergency_contact_phone: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct AssignTenantRequest {
    pub email: String,
    pub name: Option<String>,
    pub property_id: Uuid,
    pub unit_number: Option<String>,
    pub lease_start_date: DateTime<Utc>,
    pub lease_end_date: DateTime<Utc>,
    pub monthly_rent: f64,
    pub security_deposit: f64,
    pub emergency_contact_name: Option<String>,
    pub emergency_contact_phone: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct AssignTenantResponse {
    pub tenant_id: Uuid,
    pub user_id: Uuid,
    pub property_id: Uuid,
    pub invite_sent: bool,
}

#[derive(Debug, Serialize, Deserialize, ToSchema, sqlx::FromRow)]
pub struct TenantResponse {
    pub id: Uuid,
    pub user_id: Uuid,
    pub property_id: Uuid,
    pub unit_number: Option<String>,
    pub lease_start_date: DateTime<Utc>,
    pub lease_end_date: DateTime<Utc>,
    pub monthly_rent: f64,
    pub security_deposit: f64,
    pub status: TenantStatus,
    pub emergency_contact_name: Option<String>,
    pub emergency_contact_phone: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
