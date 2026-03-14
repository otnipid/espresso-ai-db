-- ========================================
-- SHOT HISTORY TABLE
-- ========================================
-- Purpose: Track changes to shot records for audit trail (requirement 1.3.3)
-- Dependencies: shots, users tables
-- Idempotent: Yes (uses IF NOT EXISTS)

CREATE TABLE IF NOT EXISTS shot_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shot_id UUID NOT NULL REFERENCES shots(id) ON DELETE CASCADE,
    
    -- Change tracking
    changed_by UUID NOT NULL REFERENCES users(id),
    change_type TEXT NOT NULL CHECK (change_type IN ('INSERT', 'UPDATE', 'DELETE')),
    changed_at TIMESTAMP DEFAULT NOW(),
    
    -- Version tracking
    from_version INTEGER,
    to_version INTEGER,
    
    -- Field-level changes (JSON for flexibility)
    field_changes JSONB,
    
    -- Full snapshot of the record at the time of change
    record_snapshot JSONB,
    
    -- Change reason (optional)
    change_reason TEXT
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_shot_history_shot_id ON shot_history(shot_id);
CREATE INDEX IF NOT EXISTS idx_shot_history_changed_by ON shot_history(changed_by);
CREATE INDEX IF NOT EXISTS idx_shot_history_changed_at ON shot_history(changed_at);
CREATE INDEX IF NOT EXISTS idx_shot_history_change_type ON shot_history(change_type);