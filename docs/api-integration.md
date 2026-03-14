# API Integration with PostgreSQL Helm Chart

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

### Option 1: Same Namespace Deployment (Recommended)

Deploy your API to the same namespace as the database for simplified networking.

#### API Deployment Configuration

```yaml
# api-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: espresso-api
  namespace: espresso-production  # Match database namespace
spec:
  replicas: 2
  selector:
    matchLabels:
      app: espresso-api
  template:
    metadata:
      labels:
        app: espresso-api
    spec:
      containers:
      - name: api
        image: your-registry/espresso-api:latest
        env:
        - name: DB_HOST
          value: "espresso-db-postgres"  # Same namespace, use short name
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: database
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: password
        ports:
        - containerPort: 3000
```

#### Shared Secret Configuration

```yaml
# postgres-credentials-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-credentials
  namespace: espresso-production
type: Opaque
stringData:
  host: "espresso-db-postgres"
  port: "5432"
  database: "espresso_ml"
  username: "postgres_user"
  password: "postgres_password"
  connection-string: "postgresql://postgres_user:postgres_password@espresso-db-postgres:5432/espresso_ml"
```

### Option 2: Cross-Namespace Communication

If your API must be in a different namespace, use the fully qualified domain name.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: espresso-api
  namespace: api-namespace
spec:
  template:
    spec:
      containers:
      - name: api
        env:
        - name: DB_HOST
          value: "espresso-db-postgres.espresso-production.svc.cluster.local"
        - name: DB_PORT
          value: "5432"
```

## Environment-Specific Configuration

### Production Environment

```yaml
# production-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-config
  namespace: espresso-production
data:
  NODE_ENV: "production"
  DB_HOST: "espresso-db-postgres"
  DB_PORT: "5432"
  DB_NAME: "espresso_ml"
  DB_SSL: "true"
  DB_POOL_MIN: "2"
  DB_POOL_MAX: "10"
  LOG_LEVEL: "info"
```

### Development Environment

```yaml
# development-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-config
  namespace: espresso-development
data:
  NODE_ENV: "development"
  DB_HOST: "espresso-db-postgres"
  DB_PORT: "5432"
  DB_NAME: "espresso_ml_dev"
  DB_SSL: "false"
  DB_POOL_MIN: "1"
  DB_POOL_MAX: "5"
  LOG_LEVEL: "debug"
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
    ssl='require' if os.getenv('DB_SSL') == 'true' else None
)
```

## Deployment Workflow Integration

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

### API Readiness Probe

```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3

livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 3
  failureThreshold: 3
```

### Health Check Endpoint

```typescript
// health.ts
import { Request, Response } from 'express';
import db from './database';

export async function healthCheck(req: Request, res: Response) {
  try {
    // Test database connection
    await db.query('SELECT 1');
    
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

## Migration Strategy

### Database Migrations

When the PostgreSQL chart is updated, you may need to run migrations:

```yaml
# migration-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: api-migrations
  namespace: espresso-production
spec:
  template:
    spec:
      containers:
      - name: migrations
        image: your-registry/espresso-api:latest
        command: ["npm", "run", "migrate"]
        env:
        - name: DB_HOST
          value: "espresso-db-postgres"
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: password
        - name: DB_NAME
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: database
      restartPolicy: OnFailure
```

## Testing Integration

### Connection Test

```bash
# Test database connectivity from API pod
kubectl exec -it deployment/espresso-api -n espresso-production -- \
  psql -h espresso-db-postgres -U $DB_USER -d $DB_NAME -c "SELECT version();"

# Test API health endpoint
kubectl port-forward svc/espresso-api 3000:3000 -n espresso-production &
curl http://localhost:3000/health
```

## Troubleshooting

### Common Issues

1. **Connection Refused**: Check if database is deployed to correct namespace
2. **Authentication Failed**: Verify secrets are correctly shared
3. **Service Not Found**: Ensure service name matches Helm release name
4. **Network Policy**: Check if network policies block cross-namespace communication

### Debug Commands

```bash
# Check database service
kubectl get svc -n espresso-production

# Check database pods
kubectl get pods -n espresso-production -l app=espresso-db-postgres

# Check API pods logs
kubectl logs -f deployment/espresso-api -n espresso-production

# Test network connectivity
kubectl exec -it deployment/espresso-api -n espresso-production -- \
  nslookup espresso-db-postgres.espresso-production.svc.cluster.local
```

## Security Considerations

1. **Secrets Management**: Use Kubernetes secrets for database credentials
2. **Network Policies**: Restrict database access to only API pods
3. **SSL/TLS**: Enable SSL for database connections in production
4. **Least Privilege**: Database users should have minimal required permissions

## Monitoring and Observability

### Database Metrics

Monitor database connection metrics in your API:
- Connection pool usage
- Query response times
- Error rates
- Connection failures

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
