-- ========================================
-- SHOT DRAFTS TABLE
-- ========================================
-- Purpose: Store auto-saved shot data (requirement 1.1.3)
-- Dependencies: users, bean_batches, machines, grinders tables
-- Idempotent: Yes (uses IF NOT EXISTS)

CREATE TABLE IF NOT EXISTS shot_drafts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Draft data (JSON for flexibility)
    draft_data JSONB NOT NULL,
    
    -- Draft metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP DEFAULT (NOW() + INTERVAL '7 days'),
    
    -- Draft status
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'converted')),
    
    -- Optional references (may be null for new drafts)
    bean_batch_id UUID REFERENCES bean_batches(id),
    machine_id UUID REFERENCES machines(id),
    grinder_id UUID REFERENCES grinders(id)
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_shot_drafts_user_id ON shot_drafts(user_id);
CREATE INDEX IF NOT EXISTS idx_shot_drafts_status ON shot_drafts(status);
CREATE INDEX IF NOT EXISTS idx_shot_drafts_expires_at ON shot_drafts(expires_at);
CREATE INDEX IF NOT EXISTS idx_shot_drafts_updated_at ON shot_drafts(updated_at);

-- Add cleanup trigger for expired drafts
CREATE OR REPLACE FUNCTION cleanup_expired_drafts()
RETURNS TRIGGER AS $$
BEGIN
    -- Auto-expire old active drafts when this trigger fires
    UPDATE shot_drafts 
    SET status = 'expired' 
    WHERE status = 'active' AND expires_at < NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-cleanup expired drafts
DROP TRIGGER IF EXISTS trigger_cleanup_expired_drafts ON shot_drafts;
CREATE TRIGGER trigger_cleanup_expired_drafts
    AFTER INSERT OR UPDATE ON shot_drafts
    FOR EACH ROW
    EXECUTE FUNCTION cleanup_expired_drafts();