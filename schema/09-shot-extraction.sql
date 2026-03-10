-- ========================================
-- SHOT EXTRACTION TABLE
-- ========================================
-- Purpose: Store shot extraction parameters
-- Dependencies: shots table
-- Idempotent: Yes (uses IF NOT EXISTS)

CREATE TABLE IF NOT EXISTS shot_extraction (
    shot_id UUID PRIMARY KEY REFERENCES shots(id) ON DELETE CASCADE,
    
    -- Temperature and preinfusion
    water_temp_c NUMERIC(4,1) CHECK (water_temp_c > 0),
    preinfusion_seconds NUMERIC(4,1) CHECK (preinfusion_seconds >= 0),
    
    -- Time and yield
    shot_time_seconds NUMERIC(5,2) CHECK (shot_time_seconds > 0),
    yield_grams NUMERIC(6,2) CHECK (yield_grams > 0),
    
    -- Pressure metrics
    peak_pressure_bar NUMERIC(4,2) CHECK (peak_pressure_bar > 0),
    avg_pressure_bar NUMERIC(4,2) CHECK (avg_pressure_bar > 0),
    
    -- Audit fields
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_shot_extraction_water_temp ON shot_extraction(water_temp_c);
CREATE INDEX IF NOT EXISTS idx_shot_extraction_shot_time ON shot_extraction(shot_time_seconds);
CREATE INDEX IF NOT EXISTS idx_shot_extraction_yield ON shot_extraction(yield_grams);