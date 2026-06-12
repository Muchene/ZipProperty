use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;
use bigdecimal::BigDecimal;

#[derive(Debug, Serialize, Deserialize, ToSchema, sqlx::FromRow)]
pub struct Payment {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub property_id: Uuid,
    pub amount: BigDecimal,
    pub payment_type: PaymentType,
    pub payment_method: PaymentMethod,
    pub payment_status: PaymentStatus,
    pub due_date: DateTime<Utc>,
    pub paid_date: Option<DateTime<Utc>>,
    pub description: Option<String>,
    pub mpesa_transaction_id: Option<String>,
    pub mpesa_receipt_number: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[sqlx(type_name = "payment_type", rename_all = "lowercase")]
pub enum PaymentType {
    Rent,
    SecurityDeposit,
    LateFee,
    MaintenanceFee,
    Other,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[sqlx(type_name = "payment_method", rename_all = "lowercase")]
pub enum PaymentMethod {
    Cash,
    Check,
    BankTransfer,
    CreditCard,
    DebitCard,
    Mpesa,
    Online,
}

#[derive(Debug, Clone, Serialize, Deserialize, ToSchema, sqlx::Type)]
#[sqlx(type_name = "payment_status", rename_all = "lowercase")]
pub enum PaymentStatus {
    Pending,
    Paid,
    Overdue,
    Cancelled,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct CreatePaymentRequest {
    pub tenant_id: Uuid,
    pub property_id: Uuid,
    pub amount: f64,
    pub payment_type: PaymentType,
    pub due_date: DateTime<Utc>,
    pub description: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct ProcessPaymentRequest {
    pub payment_method: PaymentMethod,
    pub paid_date: DateTime<Utc>,
    pub mpesa_transaction_id: Option<String>,
    pub mpesa_receipt_number: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct PaymentResponse {
    pub id: Uuid,
    pub tenant_id: Uuid,
    pub property_id: Uuid,
    pub amount: f64,
    pub payment_type: PaymentType,
    pub payment_method: Option<PaymentMethod>,
    pub payment_status: PaymentStatus,
    pub due_date: DateTime<Utc>,
    pub paid_date: Option<DateTime<Utc>>,
    pub description: Option<String>,
    pub mpesa_transaction_id: Option<String>,
    pub mpesa_receipt_number: Option<String>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}
