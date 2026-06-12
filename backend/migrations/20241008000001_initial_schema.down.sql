-- This file should undo anything in `up.sql`
DROP TABLE IF EXISTS maintenance_requests;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS tenants;
DROP TABLE IF EXISTS properties;
DROP TABLE IF EXISTS users;

DROP TYPE IF EXISTS maintenance_category;
DROP TYPE IF EXISTS maintenance_status;
DROP TYPE IF EXISTS maintenance_priority;
DROP TYPE IF EXISTS payment_status;
DROP TYPE IF EXISTS payment_method;
DROP TYPE IF EXISTS payment_type;
DROP TYPE IF EXISTS tenant_status;
DROP TYPE IF EXISTS property_type;
DROP TYPE IF EXISTS user_role;

DROP FUNCTION IF EXISTS update_updated_at_column();
