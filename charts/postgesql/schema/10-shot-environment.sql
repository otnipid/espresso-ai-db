-- ========================================
-- SHOT ENVIRONMENT TABLE
-- ========================================
-- Purpose: Store environmental conditions during shot
-- Dependencies: shots table
-- Idempotent: Yes (uses IF NOT EXISTS)

CREATE TABLE IF NOT EXISTS shot_environment (
    shot_id UUID PRIMARY KEY REFERENCES shots(id) ON DELETE CASCADE,
    
    -- Ambient conditions
    ambient_temp_c NUMERIC(4,1),
    humidity_percent NUMERIC(4,1) CHECK (humidity_percent >= 0 AND humidity_percent <= 100),
    
    -- Water information
    water_source TEXT,
    estimated_water_hardness_ppm INTEGER CHECK (estimated_water_hardness_ppm >= 0),
    
    -- Machine state
    machine_warmup_minutes INTEGER CHECK (machine_warmup_minutes >= 0),
    shots_since_clean INTEGER CHECK (shots_since_clean >= 0),
    
    -- Audit fields
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_shot_environment_ambient_temp ON shot_environment(ambient_temp_c);
CREATE INDEX IF NOT EXISTS idx_shot_environment_humidity ON shot_environment(humidity_percent);