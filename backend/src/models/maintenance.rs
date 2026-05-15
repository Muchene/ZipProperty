use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;
use bigdecimal::BigDecimal;

#[derive(Debug, Serialize, Deserialize, ToSchema, sqlx::FromRow)]
pub struct MaintenanceRequest {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub property_id: Uuid,
    pub title: String,
    pub description: String,
    pub priority: MaintenancePriority,
    pub status: MaintenanceStatus,
    pub category: MaintenanceCategory,
    pub assigned_to: Option<Uuid>,
    pub estimated_cost: Option<BigDecimal>,
    pub actual_cost: Option<BigDecimal>,
    pub scheduled_date: Option<DateTime<Utc>>,
    pub completed_date: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[sqlx(type_name = "maintenance_priority", rename_all = "lowercase")]
pub enum MaintenancePriority {
    Low,
    Medium,
    High,
    Emergency,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[sqlx(type_name = "maintenance_status", rename_all = "lowercase")]
pub enum MaintenanceStatus {
    Pending,
    InProgress,
    Completed,
    Cancelled,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[sqlx(type_name = "maintenance_category", rename_all = "lowercase")]
pub enum MaintenanceCategory {
    Plumbing,
    Electrical,
    Hvac,
    Appliances,
    Flooring,
    Painting,
    Security,
    Landscaping,
    Other,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct CreateMaintenanceRequest {
    pub property_id: Uuid,
    pub title: String,
    pub description: String,
    pub priority: MaintenancePriority,
    pub category: MaintenanceCategory,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct UpdateMaintenanceRequest {
    pub title: Option<String>,
    pub description: Option<String>,
    pub priority: Option<MaintenancePriority>,
    pub status: Option<MaintenanceStatus>,
    pub category: Option<MaintenanceCategory>,
    pub assigned_to: Option<Uuid>,
    pub estimated_cost: Option<f64>,
    pub actual_cost: Option<f64>,
    pub scheduled_date: Option<DateTime<Utc>>,
    pub completed_date: Option<DateTime<Utc>>,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct MaintenanceResponse {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub property_id: Uuid,
    pub title: String,
    pub description: String,
    pub priority: MaintenancePriority,
    pub status: MaintenanceStatus,
    pub category: MaintenanceCategory,
    pub assigned_to: Option<Uuid>,
    pub estimated_cost: Option<f64>,
    pub actual_cost: Option<f64>,
    pub scheduled_date: Option<DateTime<Utc>>,
    pub completed_date: Option<DateTime<Utc>>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
