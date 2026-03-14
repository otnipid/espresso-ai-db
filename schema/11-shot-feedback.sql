-- ========================================
-- SHOT FEEDBACK TABLE
-- ========================================
-- Purpose: Store subjective shot feedback and ratings
-- Dependencies: shots table
-- Idempotent: Yes (uses IF NOT EXISTS)

CREATE TABLE IF NOT EXISTS shot_feedback (
    shot_id UUID PRIMARY KEY REFERENCES shots(id) ON DELETE CASCADE,
    
    -- Overall rating (1-10 scale)
    overall_score INTEGER CHECK (overall_score BETWEEN 1 AND 10),
    
    -- Flavor profile ratings (1-10 scale)
    acidity INTEGER CHECK (acidity BETWEEN 1 AND 10),
    sweetness INTEGER CHECK (sweetness BETWEEN 1 AND 10),
    bitterness INTEGER CHECK (bitterness BETWEEN 1 AND 10),
    body INTEGER CHECK (body BETWEEN 1 AND 10),
    
    -- Extraction assessment
    extraction_assessment TEXT CHECK (
        extraction_assessment IN ('under', 'balanced', 'over')
    ),
    
    -- Free-form notes
    notes TEXT,
    
    -- Audit fields
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_shot_feedback_overall_score ON shot_feedback(overall_score);
CREATE INDEX IF NOT EXISTS idx_shot_feedback_extraction_assessment ON shot_feedback(extraction_assessment);