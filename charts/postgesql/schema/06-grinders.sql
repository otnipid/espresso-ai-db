-- ========================================
-- GRINDERS TABLE
-- ========================================
-- Purpose: Store coffee grinder information
-- Dependencies: None (uses uuid-ossp extension)
-- Idempotent: Yes (uses IF NOT EXISTS)

CREATE TABLE IF NOT EXISTS grinders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model TEXT NOT NULL,
    manufacturer TEXT,
    burr_type TEXT,
    burr_install_date DATE,
    serial_number TEXT UNIQUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_grinders_model ON grinders(model);
CREATE INDEX IF NOT EXISTS idx_grinders_manufacturer ON grinders(manufacturer);