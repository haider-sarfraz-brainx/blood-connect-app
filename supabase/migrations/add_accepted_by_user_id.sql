-- Migration: Add accepted_by_user_id column to blood_requests table
-- This allows tracking which user accepted each request

-- Add the column
ALTER TABLE blood_requests 
ADD COLUMN IF NOT EXISTS accepted_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_blood_requests_accepted_by ON blood_requests(accepted_by_user_id);

-- Add RLS policy to allow users to view requests they accepted
-- Drop policy if it exists first (PostgreSQL doesn't support IF NOT EXISTS for policies)
DROP POLICY IF EXISTS "Users can view accepted requests" ON blood_requests;

CREATE POLICY "Users can view accepted requests"
  ON blood_requests
  FOR SELECT
  USING (auth.uid() = accepted_by_user_id);

-- Update the accept policy to require accepted_by_user_id to be set
DROP POLICY IF EXISTS "Users can accept pending requests" ON blood_requests;

CREATE POLICY "Users can accept pending requests"
  ON blood_requests
  FOR UPDATE
  USING (status = 'pending' AND auth.uid() != user_id)
  WITH CHECK (status = 'in-progress' AND auth.uid() != user_id AND accepted_by_user_id = auth.uid());
