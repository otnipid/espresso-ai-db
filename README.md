# Espresso ML Database Infrastructure

This repository contains the PostgreSQL database infrastructure for the Espresso ML application, providing a complete espresso shot tracking and bean management system.

## Overview

The Espresso ML database infrastructure provides:
- **Pre-configured PostgreSQL Docker image** with all necessary schemas
- **Complete database schema** for espresso shot tracking, bean management, and user analytics
- **Automated CI/CD pipeline** for building and publishing Docker images
- **Development tools** including Docker Compose configuration and health checks

## Quick Start

### Using Docker Compose (Recommended)

```bash
# Clone the repository
git clone https://github.com/otnipid/espresso-ml-db.git
cd espresso-ml-db

# Start the database
docker-compose up -d

# Check the status
docker-compose ps

# Connect to the database
docker-compose exec postgres psql -U postgres -d espresso_ml
```

### Using the Pre-built Docker Image

```bash
# Pull the image
docker pull ghcr.io/otnipid/espresso-ml-postgres:latest

# Run the container
docker run -d \
  --name espresso-ml-db \
  -e POSTGRES_PASSWORD=your_password \
  -e POSTGRES_DB=espresso_ml \
  -p 5432:5432 \
  ghcr.io/otnipid/espresso-ml-postgres:latest
```

## Database Schema

The database includes the following main schema files:

### Core Tables
- `01-extensions.sql` - PostgreSQL extensions (UUID, etc.)
- `02-users.sql` - User management and authentication
- `03-beans.sql` - Coffee bean inventory and tracking

### Equipment Management
- `04-bean-batches.sql` - Bean batch tracking
- `05-machines.sql` - Espresso machine management
- `06-grinders.sql` - Grinder configuration and tracking

### Shot Tracking
- `07-shots.sql` - Core shot records
- `08-shot-preparation.sql` - Shot preparation details
- `09-shot-extraction.sql` - Extraction parameters and metrics
- `10-shot-environment.sql` - Environmental conditions

### Analytics and Feedback
- `11-shot-feedback.sql` - User feedback and ratings
- `12-shot-history.sql` - Historical tracking
- `13-shot-drafts.sql` - Draft shot records
- `14-indexes.sql` - Database indexes for performance

## Environment Variables

### Required Variables
```bash
POSTGRES_DB=espresso_ml           # Database name
POSTGRES_USER=postgres           # Database user
POSTGRES_PASSWORD=your_password   # Database password
```

### Optional Variables
```bash
POSTGRES_INITDB_ARGS="--auth-host=scram-sha-256"  # Authentication method
```

## Development Setup

### Prerequisites
- Docker and Docker Compose
- PostgreSQL client tools (optional, for local testing)

### Local Development

1. **Clone and start the database**:
```bash
git clone https://github.com/otnipid/espresso-ml-db.git
cd espresso-ml-db
docker-compose up -d
```

2. **Configure your application**:
```bash
# Add to your .env file
DB_HOST=localhost
DB_PORT=5432
DB_NAME=espresso_ml
DB_USER=postgres
DB_PASSWORD=your_password
```

3. **Test the connection**:
```bash
# Using Docker Compose
docker-compose exec postgres pg_isready -U postgres

# Using psql from host
psql -h localhost -p 5432 -U postgres -d espresso_ml
```

### Building the Docker Image

```bash
# Build locally
./build-image.sh

# Or using Docker directly
docker build -t espresso-ml-postgres:latest .
```

## Configuration Files

### Docker Compose (`docker-compose.yml`)
- Pre-configured for local development
- Includes health checks and volume persistence
- Environment variable support

### Dockerfile
- Multi-stage build based on PostgreSQL 15
- Automatic schema initialization
- Health check integration

### Health Check (`healthcheck.sh`)
- Database connectivity verification
- Schema validation
- Container readiness checks

## Integration with Applications

### Node.js/TypeScript
```typescript
import { Pool } from 'pg';

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'espresso_ml',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || '',
});
```

### Python/SQLAlchemy
```python
from sqlalchemy import create_engine

DATABASE_URL = f"postgresql://{os.getenv('DB_USER')}:{os.getenv('DB_PASSWORD')}@{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/{os.getenv('DB_NAME')}"
engine = create_engine(DATABASE_URL)
```

### Go/pgx
```go
import "github.com/jackc/pgx/v5/pgxpool"

connString := fmt.Sprintf("postgres://%s:%s@%s:%s/%s",
    os.Getenv("DB_USER"), os.Getenv("DB_PASSWORD"),
    os.Getenv("DB_HOST"), os.Getenv("DB_PORT"), os.Getenv("DB_NAME"))
```

## CI/CD Pipeline

The repository includes automated workflows:

### CI Pipeline (`.github/workflows/ci.yml`)
- **Linting**: Dockerfile and docker-compose validation
- **Schema Validation**: SQL syntax and structure testing
- **Security Scanning**: Vulnerability assessment with Trivy
- **Image Building**: Automated Docker image creation

### Deploy Pipeline (`.github/workflows/deploy.yml`)
- **Multi-platform Builds**: Linux AMD64 and ARM64 support
- **Registry Publishing**: GitHub Container Registry integration
- **Security Scanning**: Image vulnerability assessment
- **Image Testing**: Automated database initialization testing

## Security Features

- **SCRAM-SHA-256 Authentication**: Secure password hashing
- **Health Checks**: Container readiness verification
- **Vulnerability Scanning**: Automated security assessment
- **SBOM Generation**: Software Bill of Materials tracking
- **Secret Scanning**: Gitleaks integration for credential detection

## Production Deployment

### Environment Configuration

For production deployments:

1. **Use strong passwords**:
```bash
POSTGRES_PASSWORD=$(openssl rand -base64 32)
```

2. **Enable SSL/TLS**:
```bash
POSTGRES_INITDB_ARGS="--auth-host=scram-sha-256 --ssl=on"
```

3. **Configure resource limits**:
```yaml
services:
  postgres:
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
```

### Monitoring

- **Health Checks**: Built-in container health monitoring
- **Connection Pooling**: Application-level connection management
- **Performance Metrics**: Query performance and connection tracking

## Backup and Recovery

### Backup
```bash
# Using Docker Compose
docker-compose exec postgres pg_dump -U postgres espresso_ml > backup.sql

# Using Docker
docker exec espresso-ml-db pg_dump -U postgres espresso_ml > backup.sql
```

### Restore
```bash
# Using Docker Compose
docker-compose exec -T postgres psql -U postgres espresso_ml < backup.sql

# Using Docker
docker exec -i espresso-ml-db psql -U postgres espresso_ml < backup.sql
```

## Troubleshooting

### Common Issues

1. **Connection Refused**:
   - Check if the container is running: `docker-compose ps`
   - Verify port mapping: `docker-compose logs postgres`

2. **Authentication Failed**:
   - Verify environment variables
   - Check password complexity requirements

3. **Schema Not Initialized**:
   - Review initialization logs: `docker-compose logs postgres`
   - Verify SQL file permissions

### Debug Commands

```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs postgres

# Test database connection
docker-compose exec postgres pg_isready -U postgres

# Inspect schema
docker-compose exec postgres psql -U postgres -d espresso_ml -c "\dt"
```

## Contributing

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/new-feature`
3. **Make changes** and test locally
4. **Submit a pull request** with description

### Development Guidelines

- **SQL Changes**: Update individual schema files
- **Docker Changes**: Test with `docker build --no-cache`
- **Documentation**: Update README and relevant docs
- **Testing**: Verify schema changes work correctly

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/otnipid/espresso-ml-db/issues)
- **Documentation**: [docs/](./docs/)
- **Discussions**: [GitHub Discussions](https://github.com/otnipid/espresso-ml-db/discussions)

## Version History

- **v1.0.0**: Initial release with complete schema
- **v1.1.0**: Added health checks and security scanning
- **v1.2.0**: Multi-platform Docker image support

---

**Note**: This repository focuses solely on the PostgreSQL database infrastructure. For application code and other components, refer to the main Espresso ML project repositories.
