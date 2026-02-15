-- ========================================
-- SHOTS TABLE (CORE ENTITY)
-- ========================================
-- Purpose: Store shot records with soft delete and audit fields
-- Dependencies: users, bean_batches, machines, grinders tables
-- Requirements: 1.4.1 (soft delete), 1.3.3 (change tracking)
-- Idempotent: Yes (uses IF NOT EXISTS)

CREATE TABLE IF NOT EXISTS shots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    bean_batch_id UUID NOT NULL REFERENCES bean_batches(id),
    machine_id UUID NOT NULL REFERENCES machines(id),
    grinder_id UUID NOT NULL REFERENCES grinders(id),
    
    -- Shot metadata
    shot_type TEXT CHECK (shot_type IN ('ristretto', 'normale', 'lungo')),
    pulled_at TIMESTAMP DEFAULT NOW(),
    success BOOLEAN DEFAULT false,
    
    -- Soft delete support (requirement 1.4.1)
    deleted_at TIMESTAMP,
    
    -- Audit fields for change tracking (requirement 1.3.3)
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_by UUID REFERENCES users(id),
    updated_at TIMESTAMP DEFAULT NOW(),
    version INTEGER DEFAULT 1
);

-- Add indexes for performance and filtering
CREATE INDEX IF NOT EXISTS idx_shots_user_id ON shots(user_id);
CREATE INDEX IF NOT EXISTS idx_shots_bean_batch_id ON shots(bean_batch_id);
CREATE INDEX IF NOT EXISTS idx_shots_machine_id ON shots(machine_id);
CREATE INDEX IF NOT EXISTS idx_shots_grinder_id ON shots(grinder_id);
CREATE INDEX IF NOT EXISTS idx_shots_pulled_at ON shots(pulled_at);
CREATE INDEX IF NOT EXISTS idx_shots_success ON shots(success);
CREATE INDEX IF NOT EXISTS idx_shots_deleted_at ON shots(deleted_at) WHERE deleted_at IS NULL;