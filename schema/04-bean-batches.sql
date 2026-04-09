-- ========================================
-- BEAN BATCHES TABLE
-- ========================================
-- Purpose: Store coffee bean and batch information (consolidated)
-- Dependencies: None (self-contained)
-- Idempotent: Yes (uses IF NOT EXISTS)

CREATE TABLE IF NOT EXISTS bean_batches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    roaster TEXT,
    country TEXT,
    roast_level TEXT,
    roast_date DATE,
    bag_open_date DATE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_bean_batches_name ON bean_batches(name);
CREATE INDEX IF NOT EXISTS idx_bean_batches_roaster ON bean_batches(roaster);
CREATE INDEX IF NOT EXISTS idx_bean_batches_country ON bean_batches(country);
CREATE INDEX IF NOT EXISTS idx_bean_batches_roast_date ON bean_batches(roast_date);