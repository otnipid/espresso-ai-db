#!/bin/bash
set -e

# Custom setup script that runs after database initialization
# This executes all schema files in the correct order

echo "🔧 Running custom Espresso ML database setup..."

# Wait for PostgreSQL to be ready
until pg_isready -U "$POSTGRES_USER"; do
    echo "⏳ Waiting for PostgreSQL to be ready..."
    sleep 2
done

# Execute schema files in order
echo "📋 Loading Espresso ML database schemas..."
cd /docker-entrypoint-initdb.d/schema

# First, execute the master schema file that includes all others
if [ -f "00-schema.sql" ]; then
    echo "🔧 Executing 00-schema.sql (master schema file)..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" < 00-schema.sql
else
    # Fallback: execute individual files in order
    for file in 01-*.sql 02-*.sql 03-*.sql 04-*.sql 05-*.sql 06-*.sql 07-*.sql 08-*.sql 09-*.sql 10-*.sql 11-*.sql 12-*.sql 13-*.sql 14-*.sql; do
        if [ -f "$file" ]; then
            echo "🔧 Executing $file..."
            psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" < "$file"
        fi
    done
fi

# Create additional views and functions
echo "🔧 Creating views and functions..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Grant necessary permissions
    GRANT USAGE ON SCHEMA public TO PUBLIC;
    GRANT SELECT ON ALL TABLES IN SCHEMA public TO PUBLIC;
    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO PUBLIC;

    -- Create a simple function to check database status
    CREATE OR REPLACE FUNCTION database_status()
    RETURNS TEXT AS \$\$
    BEGIN
        RETURN 'Espresso ML database is ready';
    END;
    \$\$ LANGUAGE plpgsql;
EOSQL

echo "✅ Espresso ML database setup completed successfully!"

# Create a marker file to indicate successful initialization
touch /var/lib/postgresql/data/espresso-ml-initialized

echo "🎉 Espresso ML database is ready for use!"
