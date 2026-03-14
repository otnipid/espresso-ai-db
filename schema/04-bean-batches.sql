-- ========================================
-- BEAN BATCHES TABLE
-- ========================================
-- Purpose: Store specific bean batch information (roast details)
-- Dependencies: beans table
-- Idempotent: Yes (uses IF NOT EXISTS)

CREATE TABLE IF NOT EXISTS bean_batches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bean_id UUID NOT NULL REFERENCES beans(id) ON DELETE CASCADE,
    roast_level TEXT,
    roast_date DATE,
    roast_degree INTEGER CHECK (roast_degree >= 0 AND roast_degree <= 100),
    bag_open_date DATE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_bean_batches_bean_id ON bean_batches(bean_id);
CREATE INDEX IF NOT EXISTS idx_bean_batches_roast_date ON bean_batches(roast_date);