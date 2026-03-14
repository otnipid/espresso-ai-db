-- ========================================
-- ADDITIONAL INDEXES FOR PERFORMANCE
-- ========================================
-- Purpose: Create composite indexes for common query patterns
-- Dependencies: All tables
-- Idempotent: Yes (uses IF NOT EXISTS)

-- Composite indexes for shot list filtering and sorting
CREATE INDEX IF NOT EXISTS idx_shots_user_pulled_at ON shots(user_id, pulled_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_shots_success_pulled_at ON shots(success, pulled_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_shots_bean_pulled_at ON shots(bean_batch_id, pulled_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_shots_machine_pulled_at ON shots(machine_id, pulled_at DESC) WHERE deleted_at IS NULL;

-- Index for shot statistics queries
CREATE INDEX IF NOT EXISTS idx_shots_stats ON shots(pulled_at, success) WHERE deleted_at IS NULL;

-- Index for draft cleanup
CREATE INDEX IF NOT EXISTS idx_shot_drafts_cleanup ON shot_drafts(status, expires_at) WHERE status = 'active';

-- GIN indexes for JSONB fields
CREATE INDEX IF NOT EXISTS idx_shot_history_field_changes_gin ON shot_history USING GIN(field_changes);
CREATE INDEX IF NOT EXISTS shot_drafts_draft_data_gin ON shot_drafts USING GIN(draft_data);