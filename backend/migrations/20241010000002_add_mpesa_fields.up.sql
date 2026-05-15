-- Add M-Pesa specific fields to payments table
ALTER TABLE payments 
ADD COLUMN mpesa_transaction_id VARCHAR,
ADD COLUMN mpesa_receipt_number VARCHAR;

-- Add index for M-Pesa transaction lookups
CREATE INDEX idx_payments_mpesa_transaction_id ON payments(mpesa_transaction_id);
CREATE INDEX idx_payments_mpesa_receipt_number ON payments(mpesa_receipt_number);