-- ========================================
-- SHOT PREPARATION TABLE
-- ========================================
-- Purpose: Store shot preparation parameters
-- Dependencies: shots table
-- Idempotent: Yes (uses IF NOT EXISTS)

CREATE TABLE IF NOT EXISTS shot_preparation (
    shot_id UUID PRIMARY KEY REFERENCES shots(id) ON DELETE CASCADE,
    
    -- Grind parameters
    grind_setting INTEGER,
    dose_grams NUMERIC(5,2) CHECK (dose_grams > 0),
    
    -- Basket information
    basket_type TEXT,
    basket_size_grams INTEGER CHECK (basket_size_grams > 0),
    
    -- Distribution and tamping
    distribution_method TEXT,
    tamp_type TEXT,
    tamp_pressure_category TEXT,
    
    -- Audit fields
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_shot_preparation_grind_setting ON shot_preparation(grind_setting);
CREATE INDEX IF NOT EXISTS idx_shot_preparation_basket_type ON shot_preparation(basket_type);