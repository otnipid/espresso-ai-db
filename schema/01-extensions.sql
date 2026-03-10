-- ========================================
-- EXTENSIONS
-- ========================================
-- Purpose: Enable required PostgreSQL extensions
-- Dependencies: None
-- Idempotent: Yes (uses IF NOT EXISTS)

-- Enable UUID generation for primary keys
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pg_stat_statements for query performance monitoring
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";