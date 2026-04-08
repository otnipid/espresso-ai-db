-- ========================================
-- ESPRESSO ML DATABASE SCHEMA
-- ========================================
-- Purpose: Master schema file that includes all modular SQL files
-- Dependencies: None
-- Order: Files are numbered to ensure proper dependency order
-- Idempotent: Yes (all sub-files use IF NOT EXISTS)
-- Updated: 2026-03-15 (Fixed for Docker container loading)

-- Load extensions first
\ir 01-extensions.sql

-- Load core entity tables (no dependencies)
\ir 02-users.sql
\ir 03-beans.sql
\ir 05-machines.sql
\ir 06-grinders.sql

-- Load tables with dependencies
\ir 04-bean-batches.sql  -- depends on beans
\ir 07-shots.sql         -- depends on users, bean_batches, machines, grinders

-- Load shot-related tables (depend on shots)
\ir 08-shot-preparation.sql
\ir 09-shot-extraction.sql
\ir 10-shot-environment.sql
\ir 11-shot-feedback.sql

-- Load audit and draft tables
\ir 12-shot-history.sql   -- depends on shots, users
\ir 13-shot-drafts.sql    -- depends on users, bean_batches, machines, grinders

-- Load performance indexes last
\ir 14-indexes.sql

-- Schema creation complete
SELECT 'Espresso ML schema created successfully' as status;
