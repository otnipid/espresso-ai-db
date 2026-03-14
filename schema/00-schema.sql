-- ========================================
-- ESPRESSO ML DATABASE SCHEMA
-- ========================================
-- Purpose: Master schema file that includes all modular SQL files
-- Dependencies: None
-- Order: Files are numbered to ensure proper dependency order
-- Idempotent: Yes (all sub-files use IF NOT EXISTS)
-- Updated: 2026-03-10 (CI fixes applied)

-- Load extensions first
\i 01-extensions.sql

-- Load core entity tables (no dependencies)
\i 02-users.sql
\i 03-beans.sql
\i 05-machines.sql
\i 06-grinders.sql

-- Load tables with dependencies
\i 04-bean-batches.sql  -- depends on beans
\i 07-shots.sql         -- depends on users, bean_batches, machines, grinders

-- Load shot-related tables (depend on shots)
\i 08-shot-preparation.sql
\i 09-shot-extraction.sql
\i 10-shot-environment.sql
\i 11-shot-feedback.sql

-- Load audit and draft tables
\i 12-shot-history.sql   -- depends on shots, users
\i 13-shot-drafts.sql    -- depends on users, bean_batches, machines, grinders

-- Load performance indexes last
\i 14-indexes.sql

-- Schema creation complete
SELECT 'Espresso ML schema created successfully' as status;# Updated: Wed Mar 11 19:22:45 AWST 2026
# Updated again: Wed Mar 11 19:25:11 AWST 2026
# Updated: Wed Mar 11 19:29:40 AWST 2026
# Updated: Wed Mar 11 19:33:40 AWST 2026
# Updated: Wed Mar 11 19:40:27 AWST 2026
# Updated: Wed Mar 11 19:49:01 AWST 2026
