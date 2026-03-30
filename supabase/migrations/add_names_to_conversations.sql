-- Add name columns to conversations for real-time display without joins
ALTER TABLE conversations 
ADD COLUMN IF NOT EXISTS initiator_name TEXT,
ADD COLUMN IF NOT EXISTS recipient_name TEXT;

-- Trigger to auto-populate names on insert
CREATE OR REPLACE FUNCTION populate_conversation_names()
RETURNS TRIGGER AS $$
BEGIN
    -- Fetch initiator name
    SELECT name INTO NEW.initiator_name FROM users WHERE id = NEW.initiator_id;
    -- Fetch recipient name
    SELECT name INTO NEW.recipient_name FROM users WHERE id = NEW.recipient_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_populate_conversation_names
BEFORE INSERT ON conversations
FOR EACH ROW
EXECUTE FUNCTION populate_conversation_names();

-- Update existing conversations with names from users table
UPDATE conversations c
SET initiator_name = u.name
FROM users u
WHERE c.initiator_id = u.id;

UPDATE conversations c
SET recipient_name = u.name
FROM users u
WHERE c.recipient_id = u.id;
