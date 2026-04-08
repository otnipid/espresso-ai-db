-- ========================================
-- USER FEEDBACK TABLE
-- ========================================
-- Purpose: Collect user feedback on predictions for adaptive learning
-- Dependencies: shots table
-- Idempotent: Yes (uses IF NOT EXISTS)

CREATE TABLE IF NOT EXISTS user_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prediction_id UUID NOT NULL,
    shot_id UUID NOT NULL REFERENCES shots(id) ON DELETE CASCADE,
    feedback_type TEXT NOT NULL CHECK (feedback_type IN ('parameter_accuracy', 'success_rating', 'prediction_helpfulness')),
    feedback_value NUMERIC NOT NULL CHECK (feedback_value >= 1 AND feedback_value <= 5),
    feedback_text TEXT,
    user_id UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_feedback_value CHECK (feedback_value BETWEEN 1 AND 5)
);

-- Indexes for user feedback
CREATE INDEX IF NOT EXISTS idx_user_feedback_shot_id ON user_feedback(shot_id);
CREATE INDEX IF NOT EXISTS idx_user_feedback_user_id ON user_feedback(user_id);
CREATE INDEX IF NOT EXISTS idx_user_feedback_type ON user_feedback(feedback_type);

-- Comments for documentation
COMMENT ON TABLE user_feedback IS 'Collects user feedback on predictions for adaptive learning and model improvement';