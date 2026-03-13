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

# Connect to database and run additional setup
if [ -n "$POSTGRES_PASSWORD" ]; then
    # Password provided via environment variable (GitHub Actions)
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --password "$POSTGRES_PASSWORD" --dbname "$POSTGRES_DB" <<-EOSQL
else
    echo "❌ ERROR: POSTGRES_PASSWORD environment variable is required"
    exit 1
fi
    -- Create a view for active shots (useful for analytics)
    CREATE OR REPLACE VIEW active_shots AS
    SELECT 
        s.id,
        s.user_id,
        u.username,
        b.name as bean_name,
        s.rating,
        s.created_at as shot_date
    FROM shots s
    JOIN users u ON s.user_id = u.id
    JOIN beans b ON s.bean_id = b.id
    WHERE s.rating IS NOT NULL
    ORDER BY s.created_at DESC;

    -- Create a function to get shot statistics
    CREATE OR REPLACE FUNCTION get_shot_statistics(p_user_id UUID DEFAULT NULL)
    RETURNS TABLE(
        total_shots BIGINT,
        avg_rating NUMERIC,
        favorite_bean TEXT,
        last_shot_date TIMESTAMP
    ) AS \$\$
    BEGIN
        RETURN QUERY
        SELECT 
            COUNT(*)::BIGINT,
            ROUND(AVG(s.rating), 2),
            (SELECT b.name FROM shots s2 JOIN beans b ON s2.bean_id = b.id WHERE s2.user_id = COALESCE(p_user_id, s.user_id) GROUP BY b.name ORDER BY COUNT(*) DESC LIMIT 1),
            MAX(s.created_at)
        FROM shots s
        WHERE (p_user_id IS NULL OR s.user_id = p_user_id);
    END;
    \$\$ LANGUAGE plpgsql;

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
