# Local PostgreSQL Development Setup

This guide shows how to set up PostgreSQL locally for integration testing with your Espresso ML application.

## Prerequisites

- Docker and Docker Compose installed

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
      - ./schema:/docker-entrypoint-initdb.d/schema
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U espresso_dev_user -d espresso_ml_development"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

### 2. Schema Files

The database schema is automatically initialized from the files in the `schema/` directory:
- `01-extensions.sql` - PostgreSQL extensions
- `02-users.sql` - User management tables
- `03-beans.sql` - Coffee bean tables
- And more...

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
