use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;

#[derive(Debug, Serialize, Deserialize, ToSchema, sqlx::FromRow)]
pub struct Property {
    pub id: Uuid,
    pub owner_id: Uuid,
    pub agent_id: Option<Uuid>,
    pub name: String,
    pub address: String,
    pub city: String,
    pub state: String,
    pub zip_code: String,
    pub country: String,
    pub property_type: PropertyType,
    pub total_units: i32,
    pub description: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[sqlx(type_name = "property_type", rename_all = "lowercase")]
pub enum PropertyType {
    Apartment,
    House,
    Condo,
    Townhouse,
    Commercial,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct CreatePropertyRequest {
    pub name: String,
    pub address: String,
    pub city: String,
    pub state: String,
    pub zip_code: String,
    pub country: String,
    pub property_type: PropertyType,
    pub total_units: i32,
    pub description: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct UpdatePropertyRequest {
    pub name: Option<String>,
    pub address: Option<String>,
    pub city: Option<String>,
    pub state: Option<String>,
    pub zip_code: Option<String>,
    pub country: Option<String>,
    pub property_type: Option<PropertyType>,
    pub total_units: Option<i32>,
    pub description: Option<String>,
    pub agent_id: Option<Uuid>,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct PropertyResponse {
    pub id: Uuid,
    pub owner_id: Uuid,
    pub agent_id: Option<Uuid>,
    pub name: String,
    pub address: String,
    pub city: String,
    pub state: String,
    pub zip_code: String,
    pub country: String,
    pub property_type: PropertyType,
    pub total_units: i32,
    pub description: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
