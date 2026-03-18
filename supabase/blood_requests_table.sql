CREATE TABLE IF NOT EXISTS blood_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  patient_name TEXT NOT NULL,
  blood_group TEXT NOT NULL,
  units_required INTEGER NOT NULL CHECK (units_required > 0),
  hospital_name TEXT NOT NULL,
  hospital_address TEXT,
  contact_number TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in-progress', 'fulfilled', 'cancelled')),
  notes TEXT,
  accepted_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_blood_requests_user_id ON blood_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_blood_requests_blood_group ON blood_requests(blood_group);
CREATE INDEX IF NOT EXISTS idx_blood_requests_status ON blood_requests(status);
CREATE INDEX IF NOT EXISTS idx_blood_requests_created_at ON blood_requests(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_blood_requests_accepted_by ON blood_requests(accepted_by_user_id);

ALTER TABLE blood_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own blood requests"
  ON blood_requests
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view accepted requests"
  ON blood_requests
  FOR SELECT
  USING (auth.uid() = accepted_by_user_id);

CREATE POLICY "Users can view all pending and in-progress requests"
  ON blood_requests
  FOR SELECT
  USING (status IN ('pending', 'in-progress'));

CREATE POLICY "Users can insert own blood requests"
  ON blood_requests
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own blood requests"
  ON blood_requests
  FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can accept pending requests"
  ON blood_requests
  FOR UPDATE
  USING (status = 'pending' AND auth.uid() != user_id)
  WITH CHECK (status = 'in-progress' AND auth.uid() != user_id AND accepted_by_user_id = auth.uid());

CREATE POLICY "Users can delete own blood requests"
  ON blood_requests
  FOR DELETE
  USING (auth.uid() = user_id);

CREATE TRIGGER update_blood_requests_updated_at
  BEFORE UPDATE ON blood_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
