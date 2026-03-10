#!/bin/bash
set -e

# Health check script for Espresso ML PostgreSQL container
# This verifies that the database is running and properly initialized

# Check if PostgreSQL is accepting connections
if ! pg_isready -U "${POSTGRES_USER:-postgres}"; then
    echo "❌ PostgreSQL is not ready"
    exit 1
fi

# Check if the database exists
if ! psql -U "${POSTGRES_USER:-postgres}" -lqt | cut -d \| -f 1 | grep -qw "${POSTGRES_DB:-espresso_ml}"; then
    echo "❌ Database ${POSTGRES_DB:-espresso_ml} does not exist"
    exit 1
fi

# Check if the database schema is properly initialized
if [ -f "/var/lib/postgresql/data/espresso-ml-initialized" ]; then
    echo "✅ Espresso ML database is ready and initialized"
    exit 0
else
    # Check if key tables exist (fallback if marker file is missing)
    TABLES=$(psql -U "${POSTGRES_USER:-postgres}" -d "${POSTGRES_DB:-espresso_ml}" -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('users', 'beans', 'shots')")
    
    if [ "$TABLES" -eq 3 ]; then
        echo "✅ Espresso ML database schema is ready"
        exit 0
    else
        echo "⏳ Espresso ML database is still initializing..."
        exit 1
    fi
fi
