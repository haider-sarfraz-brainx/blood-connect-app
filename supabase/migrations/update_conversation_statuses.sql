-- Add 'blocked' and 'reported' to conversation_status enum
-- Note: PostgreSQL doesn't support adding values to an enum within a transaction easily in some versions,
-- but since we are using Supabase, we can use ALTER TYPE.

ALTER TYPE conversation_status ADD VALUE IF NOT EXISTS 'blocked';
ALTER TYPE conversation_status ADD VALUE IF NOT EXISTS 'reported';
