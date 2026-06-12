-- Remove M-Pesa specific fields from payments table
DROP INDEX IF EXISTS idx_payments_mpesa_receipt_number;
DROP INDEX IF EXISTS idx_payments_mpesa_transaction_id;

ALTER TABLE payments 
DROP COLUMN IF EXISTS mpesa_receipt_number,
DROP COLUMN IF EXISTS mpesa_transaction_id;