# Database Integration Guide

This guide explains how to configure your API (in separate repositories) to consume new releases of the PostgreSQL database deployed from this database repository.

## Overview

The PostgreSQL database deploys a Helm chart that creates:
- **Database Service**: `espresso-db-postgres.{namespace}.svc.cluster.local:5432`
- **Persistent Storage**: PVC for data persistence
- **Configuration**: Environment-specific secrets and settings
- **Network Access**: ClusterIP service within the same namespace

## Service Discovery

### Production Environment
```
Host: espresso-db-postgres.espresso-production.svc.cluster.local
Port: 5432
Namespace: espresso-production
```

### Development Environment
```
Host: espresso-db-postgres.espresso-development.svc.cluster.local
Port: 5432
Namespace: espresso-development
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

### 1. Database Deployment (This Repository)

```yaml
# .github/workflows/deploy.yml
# Deploys PostgreSQL database first
```

### 2. API Deployment (Separate Repository)

Create a workflow in your API repository that:

```yaml
# .github/workflows/deploy-api.yml
name: Deploy API

on:
  workflow_run:
    workflows: ["Deploy Database"]  # Wait for database
    types:
      - completed
    branches: [main, develop]

jobs:
  deploy-api:
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    steps:
      - name: Checkout API code
        uses: actions/checkout@v4

      - name: Configure kubectl
        uses: azure/k8s-set-context@v3
        with:
          method: kubeconfig
          kubeconfig: ${{ secrets.KUBE_CONFIG_PROD }}

      - name: Deploy API
        run: |
          # Apply database secrets first
          kubectl apply -f k8s/secrets/
          
          # Apply ConfigMaps
          kubectl apply -f k8s/configmaps/
          
          # Deploy API
          kubectl apply -f k8s/deployments/
          
          # Wait for rollout
          kubectl rollout status deployment/espresso-api -n espresso-production
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

## Release Process

1. **Database Update**: Deploy new PostgreSQL chart version
2. **Database Migration**: Run any required database migrations
3. **API Update**: Deploy new API version with updated configurations
4. **Verification**: Test API connectivity and functionality
5. **Rollback**: Have rollback procedures ready for both database and API

This integration ensures your API can reliably consume PostgreSQL database releases deployed from the database repository.
