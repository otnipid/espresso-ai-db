# Local PostgreSQL Development Setup

This guide shows how to set up PostgreSQL locally for integration testing with your Espresso ML application.

## Prerequisites

- Docker and Docker Compose installed
- kubectl installed (for Kubernetes testing)
- Helm 3.x installed

## Option 1: Docker Compose (Recommended for Local Development)

### 1. Create Docker Compose File

Create `docker-compose.yml` in your project root:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    container_name: espresso-postgres-dev
    environment:
      POSTGRES_DB: espresso_ml_development
      POSTGRES_USER: espresso_dev_user
      POSTGRES_PASSWORD: dev_password_123
      POSTGRES_INITDB_ARGS: "--auth-host=scram-sha-256"
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init-db.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U espresso_dev_user -d espresso_ml_development"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

### 2. Create Initialization Script

Create `scripts/init-db.sql`:

```sql
-- Espresso ML Database Schema
-- This file initializes the database with required tables

-- =========================
-- BEANS TABLE
-- =========================
CREATE TABLE IF NOT EXISTS beans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    roaster TEXT,
    country TEXT,
    region TEXT,
    farm TEXT,
    varietal TEXT,
    processing_method TEXT,
    flavor_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- USERS TABLE
-- =========================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- TASTING_NOTES TABLE
-- =========================
CREATE TABLE IF NOT EXISTS tasting_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    bean_id UUID REFERENCES beans(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 10),
    notes TEXT,
    tasting_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- INDEXES
-- =========================
CREATE INDEX IF NOT EXISTS idx_beans_name ON beans(name);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_tasting_notes_user ON tasting_notes(user_id);
CREATE INDEX IF NOT EXISTS idx_tasting_notes_bean ON tasting_notes(bean_id);

-- =========================
-- SAMPLE DATA
-- =========================
INSERT INTO beans (name, roaster, country, region) VALUES 
('Ethiopia Yirgacheffe', 'Test Roaster', 'Ethiopia', 'Yirgacheffe'),
('Colombia Huila', 'Test Roaster', 'Colombia', 'Huila');

INSERT INTO users (username, email, password_hash, role) VALUES 
('testuser', 'test@example.com', '$2b$12$hashedpassword...', 'user');

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### 3. Start PostgreSQL

```bash
# Start the database
docker-compose up -d

# Check logs
docker-compose logs postgres

# Stop the database
docker-compose down
```

### 4. Connect to Database

```bash
# Connect using psql (install with: brew install postgresql or apt-get install postgresql-client)
docker-compose exec postgres psql -U espresso_dev_user -d espresso_ml_development

# Or connect from host
psql -h localhost -p 5432 -U espresso_dev_user -d espresso_ml_development
```

### 5. Environment Variables for Your Application

```bash
# Add to your .env file or shell profile
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=espresso_ml_development
export DB_USER=espresso_dev_user
export DB_PASSWORD=dev_password_123
export DB_URL=postgresql://espresso_dev_user:dev_password_123@localhost:5432/espresso_ml_development
```

## Option 2: Local PostgreSQL Installation

### 1. Install PostgreSQL

```bash
# macOS
brew install postgresql@15
brew services start postgresql@15

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install postgresql-15 postgresql-client-15
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### 2. Create Database and User

```bash
# Switch to postgres user
sudo -u postgres psql

# Create database
CREATE DATABASE espresso_ml_development;

# Create user
CREATE USER espresso_dev_user WITH PASSWORD 'dev_password_123';

# Grant privileges
GRANT ALL PRIVILEGES ON DATABASE espresso_ml_development TO espresso_dev_user;

# Exit
\q
```

### 3. Initialize Schema

```bash
# Run initialization script
psql -U espresso_dev_user -d espresso_ml_development -f scripts/init-db.sql
```

## Option 3: Kubernetes Local Testing

### 1. Start Local Kubernetes Cluster

```bash
# Using Kind (Kubernetes in Docker)
kind create cluster --name espresso-dev --config kind-config.yaml

# Or using Minikube
minikube start --memory=4096 --cpus=2
```

### 2. Deploy PostgreSQL with Helm

```bash
# Navigate to charts directory
cd charts/postgesql

# Install with development values
helm install espresso-db . \
  --set postgresql.password=dev_password_123 \
  --set postgresql.user=espresso_dev_user \
  --set postgresql.db=espresso_ml_development \
  --set postgresql.storage=5Gi \
  --wait \
  --timeout=10m

# Check deployment
kubectl get pods -l app=espresso-db-postgres
kubectl get services -l app=espresso-db-postgres
```

### 3. Port Forward for Local Access

```bash
# Forward PostgreSQL port to localhost
kubectl port-forward svc/espresso-db-postgres 5432:5432

# Connect locally
psql -h localhost -p 5432 -U espresso_dev_user -d espresso_ml_development
```

## Testing Your Setup

### 1. Database Connection Test

```bash
# Test connection
docker-compose exec postgres pg_isready -U espresso_dev_user -d espresso_ml_development

# Test schema
docker-compose exec postgres psql -U espresso_dev_user -d espresso_ml_development -c "\dt"

# Test data
docker-compose exec postgres psql -U espresso_dev_user -d espresso_ml_development -c "SELECT COUNT(*) FROM beans;"
```

### 2. Application Integration Test

Create a simple test script `test-db-connection.js`:

```javascript
const { Pool } = require('pg');

async function testConnection() {
  const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'espresso_ml_development',
    user: process.env.DB_USER || 'espresso_dev_user',
    password: process.env.DB_PASSWORD || 'dev_password_123',
  });

  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    console.log('✅ Database connection successful:', result.rows[0]);
    await client.end();
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    process.exit(1);
  }
}

testConnection();
```

Run the test:
```bash
# Install dependencies
npm install pg

# Run test
DB_HOST=localhost DB_PORT=5432 DB_NAME=espresso_ml_development DB_USER=espresso_dev_user DB_PASSWORD=dev_password_123 node test-db-connection.js
```

## Common Issues & Solutions

### Issue: "Connection refused"
**Solution**: Check if PostgreSQL is running
```bash
docker-compose ps  # Check container status
docker-compose logs postgres  # Check for errors
```

### Issue: "Authentication failed"
**Solution**: Verify credentials
```bash
# Check environment variables
echo $DB_USER
echo $DB_PASSWORD

# Test with psql
psql -h localhost -p 5432 -U $DB_USER -d $DB_NAME
```

### Issue: "Database does not exist"
**Solution**: Run initialization
```bash
# Create database and run schema
docker-compose exec postgres createdb -U espresso_dev_user espresso_ml_development
docker-compose exec postgres psql -U espresso_dev_user -d espresso_ml_development -f scripts/init-db.sql
```

## Development Workflow

### 1. Daily Development
```bash
# Start database
docker-compose up -d

# Run migrations (if any)
npm run migrate

# Start application
npm run dev
```

### 2. Testing
```bash
# Run tests
npm test

# Integration tests
npm run test:integration
```

### 3. Cleanup
```bash
# Stop database
docker-compose down

# Remove volumes (optional)
docker volume rm espresso-ml-infrastructure_postgres_data
```

## Production-like Testing

### 1. Using Production Values

```bash
# Test with production-like configuration
helm install espresso-db-prod . \
  --set postgresql.password=prod_password_123 \
  --set postgresql.user=espresso_prod_user \
  --set postgresql.db=espresso_ml_production \
  --set postgresql.storage=50Gi \
  --set postgresql.resources.requests.memory=2Gi \
  --set postgresql.resources.requests.cpu=500m
```

### 2. Performance Testing

```bash
# Load test data
docker-compose exec postgres psql -U espresso_dev_user -d espresso_ml_development << EOF
INSERT INTO beans (name, roaster, country, region)
SELECT 
  'Test Bean ' || generate_series(1,1000),
  'Test Roaster',
  'Test Country',
  'Test Region';
EOF

# Test queries
docker-compose exec postgres psql -U espresso_dev_user -d espresso_ml_development -c "EXPLAIN ANALYZE SELECT * FROM beans WHERE name LIKE 'Test%';"
```

## Next Steps

After setting up local development:

1. **Update your application** to use local database connection
2. **Run integration tests** to verify connectivity
3. **Test migrations** work correctly
4. **Validate data flow** between application and database
5. **Test error handling** for database disconnections

## Troubleshooting

### Check PostgreSQL Logs
```bash
# Docker Compose
docker-compose logs -f postgres

# Kubernetes
kubectl logs -l app=espresso-db-postgres -f
```

### Reset Database
```bash
# Docker Compose
docker-compose down -v
docker-compose up -d

# Kubernetes
helm uninstall espresso-db
helm install espresso-db . --set postgresql.password=dev_password_123 --set postgresql.user=espresso_dev_user --set postgresql.db=espresso_ml_development
```

### Backup and Restore
```bash
# Backup
docker-compose exec postgres pg_dump -U espresso_dev_user espresso_ml_development > backup.sql

# Restore
docker-compose exec -T postgres psql -U espresso_dev_user espresso_ml_development < backup.sql
```
