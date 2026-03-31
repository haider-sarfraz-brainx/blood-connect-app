-- Add timezone, country, and city to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS timezone TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS country TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS city TEXT;

-- Add country and city to blood_requests table
ALTER TABLE blood_requests ADD COLUMN IF NOT EXISTS country TEXT;
ALTER TABLE blood_requests ADD COLUMN IF NOT EXISTS city TEXT;
