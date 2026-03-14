-- ========================================
-- MACHINES TABLE
-- ========================================
-- Purpose: Store espresso machine information
-- Dependencies: None (uses uuid-ossp extension)
-- Idempotent: Yes (uses IF NOT EXISTS)

CREATE TABLE IF NOT EXISTS machines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model TEXT NOT NULL,
    manufacturer TEXT,
    firmware_version TEXT,
    serial_number TEXT UNIQUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_machines_model ON machines(model);
CREATE INDEX IF NOT EXISTS idx_machines_manufacturer ON machines(manufacturer);