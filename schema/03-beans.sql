-- ========================================
-- BEANS TABLE
-- ========================================
-- Purpose: Store coffee bean information
-- Dependencies: None (uses uuid-ossp extension)
-- Idempotent: Yes (uses IF NOT EXISTS)

CREATE TABLE IF NOT EXISTS beans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    roaster TEXT,
    country TEXT,
    region TEXT,
    farm TEXT,
    varietal TEXT,
    processing_method TEXT,
    altitude_m INTEGER,
    density_category TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_beans_name ON beans(name);
CREATE INDEX IF NOT EXISTS idx_beans_roaster ON beans(roaster);
CREATE INDEX IF NOT EXISTS idx_beans_country ON beans(country);