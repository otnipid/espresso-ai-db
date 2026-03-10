# Database Integration Guide

This guide explains how to configure your API (in separate repositories) to connect to the Espresso ML PostgreSQL database.

## Overview

The Espresso ML database provides:
- **Database Schema**: Complete espresso shot tracking and bean management
- **Docker Image**: Pre-configured PostgreSQL with all schemas
- **Environment Configuration**: Flexible connection settings for different environments

## Database Connection Configuration

### Environment Variables

Configure these environment variables in your application:

#### Required Variables
```bash
DB_HOST=localhost              # Database host
DB_PORT=5432                  # Database port
DB_NAME=espresso_ml           # Database name
DB_USER=postgres              # Database user
DB_PASSWORD=your_password     # Database password
```

#### Optional Variables
```bash
DB_SSL=false                  # Enable SSL (true/false)
DB_POOL_MIN=2                 # Minimum connection pool size
DB_POOL_MAX=10                # Maximum connection pool size
DB_CONNECTION_TIMEOUT=30      # Connection timeout in seconds
DB_STATEMENT_TIMEOUT=60       # Query timeout in seconds
```

#### Full Connection String
```bash
DB_URL=postgresql://postgres:your_password@localhost:5432/espresso_ml
```

## Integration Approaches

### Option 1: Docker Compose (Recommended for Development)

Add the PostgreSQL service to your `docker-compose.yml`:

```yaml
version: '3.8'

services:
  postgres:
    image: ghcr.io/otnipid/espresso-ml-postgres:develop
    # Fallback to official image if custom image is not available
    # image: postgres:15
    container_name: espresso_ml_db
    environment:
      POSTGRES_USER: ${DB_USERNAME:-postgres}
      POSTGRES_PASSWORD: ${DB_PASSWORD:-postgres}
      POSTGRES_DB: ${DB_NAME:-espresso_ml}
      POSTGRES_INITDB_ARGS: "--auth-host=scram-sha-256"
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USERNAME:-postgres}"]
      interval: 5s
      timeout: 5s
      retries: 5

  api:
    build: .
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: ${DB_NAME:-espresso_ml}
      DB_USER: ${DB_USERNAME:-postgres}
      DB_PASSWORD: ${DB_PASSWORD:-postgres}
    depends_on:
      postgres:
        condition: service_healthy

volumes:
  postgres_data:
```

### Option 2: External Database

Connect to an existing PostgreSQL instance:

```bash
# Production environment variables
export DB_HOST=your-production-db-host
export DB_PORT=5432
export DB_NAME=espresso_ml_production
export DB_USER=espresso_prod_user
export DB_PASSWORD=your_secure_password
export DB_SSL=true
```

## Database Connection Examples

### Node.js (TypeScript)

```typescript
// database.ts
import { Pool } from 'pg';

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'espresso_ml',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || '',
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  min: parseInt(process.env.DB_POOL_MIN || '2'),
  max: parseInt(process.env.DB_POOL_MAX || '10'),
  connectionTimeoutMillis: parseInt(process.env.DB_CONNECTION_TIMEOUT || '30000'),
  statement_timeout: parseInt(process.env.DB_STATEMENT_TIMEOUT || '60000'),
});

export default pool;
```

### Python (SQLAlchemy)

```python
# database.py
import os
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

DATABASE_URL = f"postgresql://{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}@{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('DB_NAME')}"

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=int(os.getenv('DB_POOL_MIN', 2)),
    max_overflow=int(os.getenv('DB_POOL_MAX', 10)),
    pool_pre_ping=True,
    connect_args={'sslmode': 'require'} if os.getenv('DB_SSL') == 'true' else {}
)
```

### Go (pgx)

```go
// database.go
package database

import (
    "context"
    "fmt"
    "os"
    "github.com/jackc/pgx/v5/pgxpool"
)

var DB *pgxpool.Pool

func Connect() error {
    dsn := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s",
        os.Getenv("DB_USER"),
        os.Getenv("DB_PASSWORD"),
        os.Getenv("DB_HOST"),
        os.Getenv("DB_PORT"),
        os.Getenv("DB_NAME"),
        getSSLMode(),
    )

    config, err := pgxpool.ParseConfig(dsn)
    if err != nil {
        return err
    }

    config.MinConns = 2
    config.MaxConns = 10

    DB, err = pgxpool.NewWithConfig(context.Background(), config)
    return err
}

func getSSLMode() string {
    if os.Getenv("DB_SSL") == "true" {
        return "require"
    }
    return "disable"
}
```

## Environment-Specific Configuration

### Development Environment

```bash
# .env.development
DB_HOST=localhost
DB_PORT=5432
DB_NAME=espresso_ml_development
DB_USER=espresso_dev_user
DB_PASSWORD=dev_password_123
DB_SSL=false
DB_POOL_MIN=1
DB_POOL_MAX=5
```

### Production Environment

```bash
# .env.production
DB_HOST=your-production-db.example.com
DB_PORT=5432
DB_NAME=espresso_ml_production
DB_USER=espresso_prod_user
DB_PASSWORD=secure_prod_password_123
DB_SSL=true
DB_POOL_MIN=2
DB_POOL_MAX=20
DB_CONNECTION_TIMEOUT=30
DB_STATEMENT_TIMEOUT=60
```

## Health Checks and Readiness

### API Health Check Endpoint

```typescript
// health.ts
import { Request, Response } from 'express';
import db from './database';

export async function healthCheck(req: Request, res: Response) {
  try {
    // Test database connection
    await db.query('SELECT NOW()');
    
    res.status(200).json({
      status: 'healthy',
      database: 'connected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      database: 'disconnected',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
}
```

### Docker Health Check

```yaml
# docker-compose.yml
api:
  build: .
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 40s
```

## Migration Strategy

### Database Initialization

The database schema is automatically initialized when using the Docker image. The schema files are executed in order:

1. `01-extensions.sql` - PostgreSQL extensions
2. `02-users.sql` - User management
3. `03-beans.sql` - Coffee bean tracking
4. `04-bean-batches.sql` - Bean batch management
5. `05-machines.sql` - Espresso machine tracking
6. `06-grinders.sql` - Grinder management
7. `07-shots.sql` - Shot records
8. `08-shot-preparation.sql` - Shot preparation details
9. `09-shot-extraction.sql` - Extraction parameters
10. `10-shot-environment.sql` - Environmental data
11. `11-shot-feedback.sql` - User feedback
12. `12-shot-history.sql` - Historical tracking
13. `13-shot-drafts.sql` - Draft shots
14. `14-indexes.sql` - Database indexes

### Application Migrations

For application-specific migrations:

```typescript
// migrations.ts
import db from './database';

export async function runMigrations() {
  try {
    // Check if migrations table exists
    await db.query(`
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        filename VARCHAR(255) UNIQUE NOT NULL,
        executed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Run pending migrations
    const migrations = ['001_add_user_preferences.sql', '002_add_shot_analytics.sql'];
    
    for (const migration of migrations) {
      const result = await db.query(
        'SELECT COUNT(*) FROM migrations WHERE filename = $1',
        [migration]
      );
      
      if (parseInt(result.rows[0].count) === 0) {
        const migrationSQL = await fs.readFile(`migrations/${migration}`, 'utf8');
        await db.query(migrationSQL);
        await db.query('INSERT INTO migrations (filename) VALUES ($1)', [migration]);
        console.log(`Migration ${migration} executed successfully`);
      }
    }
  } catch (error) {
    console.error('Migration failed:', error);
    throw error;
  }
}
```

## Testing Integration

### Connection Test

```bash
# Test database connectivity
docker-compose exec postgres pg_isready -U postgres -d espresso_ml

# Test API health endpoint
curl http://localhost:3000/health
```

### Integration Test Example

```typescript
// integration.test.ts
import request from 'supertest';
import app from './app';

describe('Database Integration', () => {
  test('should connect to database', async () => {
    const response = await request(app)
      .get('/health')
      .expect(200);
    
    expect(response.body.database).toBe('connected');
  });

  test('should retrieve beans from database', async () => {
    const response = await request(app)
      .get('/api/beans')
      .expect(200);
    
    expect(Array.isArray(response.body)).toBe(true);
  });
});
```

## Troubleshooting

### Common Issues

1. **Connection Refused**: Check if PostgreSQL is running and accessible
2. **Authentication Failed**: Verify credentials and database permissions
3. **Database Not Found**: Ensure database exists and schema is initialized
4. **SSL Errors**: Configure SSL settings correctly for production

### Debug Commands

```bash
# Check database connection
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT version();"

# Test with Docker Compose
docker-compose logs postgres
docker-compose exec postgres psql -U postgres -c "\dt"

# Check network connectivity
telnet $DB_HOST $DB_PORT
```

## Security Considerations

1. **Environment Variables**: Store sensitive data in environment variables or secret management systems
2. **SSL/TLS**: Enable SSL for database connections in production
3. **Connection Pooling**: Use appropriate pool sizes to prevent connection exhaustion
4. **Least Privilege**: Database users should have minimal required permissions
5. **Password Security**: Use strong, unique passwords for each environment

## Monitoring and Observability

### Database Metrics

Monitor these metrics in your application:
- Connection pool usage
- Query response times
- Error rates
- Connection failures
- Active connections

### Logging

Include database connection information in logs:

```typescript
logger.info('Database connected', {
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  poolSize: pool.totalCount,
  idleCount: pool.idleCount,
  waitingCount: pool.waitingCount
});
```

This integration guide ensures your API can reliably connect to the Espresso ML PostgreSQL database across different environments.
