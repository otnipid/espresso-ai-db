# Deploy to Development (Aiven)

## Description
This workflow deploys the Espresso ML database schema to the Aiven PostgreSQL development environment when code is merged to the develop branch.

## When to Use This Workflow
Use this workflow when:
- You want to deploy database changes to the development environment
- Code on the develop branch needs to be deployed

## Prerequisites
- Aiven PostgreSQL service must be set up and running
- GitHub secrets must be configured (see docs/aiven-deployment-setup.md)

## Steps

### Step 1: Deployment Trigger
Trigger the deployment using the GitHub CLI:

```bash
# Trigger deployment workflow
gh workflow run "Deploy Database" --field environment=development

# Monitor the deployment
gh run watch --job deploy-development
```

## Step 2: Monitor Deployment Progress

### Check Deployment Status
```bash
# List recent workflow runs
gh run list --workflow="Deploy Database"

# Watch the specific deployment
gh run watch <run-id>

# View detailed logs
gh run view <run-id> --log
```

### Key Deployment Steps to Monitor
1. **Setup Aiven CLI** - Installs and authenticates with Aiven
2. **Deploy Schema** - Applies SQL schema files in order
3. **Health Checks** - Verifies database connectivity and data integrity
4. **Deployment Status** - Updates GitHub commit status

## Step 3: Verify Deployment Success

#### Check GitHub Actions Status
```bash
# Get deployment run status
gh run list --workflow="Deploy Database" --limit=3

# View detailed run results
gh run view <run-id> --json status,conclusion | jq '.conclusion'

# Check specific job status
gh run view <run-id> --job deploy-development --json status,conclusion
```

#### Verify Aiven Service Status
```bash
# Check Aiven service is running
avn service get <service-name> --format json | jq '.state'

# Get service connection details
avn service get <service-name> --format json | jq -r '.service_uri'

# Check service metrics
avn service metrics <service-name> --format json
```

#### Verify Database Schema via CLI
```bash
# Extract connection details from Aiven
SERVICE_URI=$(avn service get <service-name> --format json | jq -r '.service_uri')
DB_HOST=$(echo "$SERVICE_URI" | awk -F'[@:] '{print $4}')
DB_PORT=$(echo "$SERVICE_URI" | awk -F'[@:] '{print $5}')
DB_NAME=$(echo "$SERVICE_URI" | awk -F'[/] '{print $4}')

# REQUIREMENT: Database credentials must be set as environment variables
if [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
    echo "❌ ERROR: Database credentials not set!"
    echo "📋 Required environment variables:"
    echo "   export DB_USER=\"your_database_user\""
    echo "   export DB_PASSWORD=\"your_database_password\""
    exit 1
fi

echo "🔐 Using database credentials for user: $DB_USER"

# Verify tables exist using psql
TABLES=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT tablename FROM pg_tables WHERE schemaname = 'public';")
echo "📊 Tables found: $TABLES"

# Check table counts
USER_COUNT=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM users;")
BEAN_COUNT=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM beans;")

echo "👥 Users: $USER_COUNT"
echo "🫘 Beans: $BEAN_COUNT"
```

#### Check Deployment Logs
```bash
# Get deployment logs
gh run view <run-id> --log

# Filter for specific deployment steps
gh run view <run-id> --log | grep -A 10 "Deploy Schema"

# Check for errors in deployment
gh run view <run-id> --log | grep -i error
```

#### Automated Verification Script
```bash
#!/bin/bash
# verify-deployment.sh

echo "🔍 Verifying deployment to development environment..."

# REQUIREMENT: Database credentials must be set as environment variables
if [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
    echo "❌ ERROR: Database credentials not set!"
    echo "📋 Required environment variables:"
    echo "   export DB_USER=\"your_database_user\""
    echo "   export DB_PASSWORD=\"your_database_password\""
    echo "   export AIVEN_SERVICE_NAME=\"your_service_name\""
    exit 1
fi

# Set your Aiven service details
export AIVEN_SERVICE_NAME="${AIVEN_SERVICE_NAME:-your-service-name}"

echo "🔐 Using database credentials for user: $DB_USER"
echo "🏢 Using Aiven service: $AIVEN_SERVICE_NAME"

# Get latest deployment run
RUN_ID=$(gh run list --workflow="Deploy Database" --limit=1 --json databaseId --jq '.[0].databaseId')

# Check deployment status
STATUS=$(gh run view "$RUN_ID" --json conclusion --jq '.conclusion')

if [ "$STATUS" = "success" ]; then
    echo "✅ Deployment completed successfully"
    
    # Verify Aiven service
    SERVICE_STATE=$(avn service get "$AIVEN_SERVICE_NAME" --format json | jq -r '.state')
    echo "📊 Aiven service state: $SERVICE_STATE"
    
    # Verify database tables
    SERVICE_URI=$(avn service get "$AIVEN_SERVICE_NAME" --format json | jq -r '.service_uri')
    DB_HOST=$(echo "$SERVICE_URI" | awk -F'[@:] '{print $4}')
    DB_PORT=$(echo "$SERVICE_URI" | awk -F'[@:] '{print $5}')
    DB_NAME=$(echo "$SERVICE_URI" | awk -F'[/] '{print $4}')
    
    TABLE_COUNT=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
    echo "📋 Database tables created: $TABLE_COUNT"
    
    echo "🎉 Deployment verification complete!"
else
    echo "❌ Deployment failed or incomplete"
    echo "📋 Check logs: gh run view $RUN_ID --log"
    exit 1
fi
```

## Troubleshooting

### Common Issues

**Authentication Failed**
```bash
# REQUIREMENT: Aiven token must be set as environment variable
if [ -z "$AIVEN_TOKEN" ]; then
    echo "❌ ERROR: AIVEN_TOKEN not set!"
    echo "📋 Required: export AIVEN_TOKEN=\"your_aiven_token\""
    exit 1
fi

# Test Aiven token authentication
echo "Testing Aiven authentication..."
echo "$AIVEN_TOKEN" | avn user authenticate --token

# Check current user
avn user whoami

# Test service access
avn service list
```

**Database Connection Failed**
```bash
# REQUIREMENT: Database credentials must be set as environment variables
if [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ] || [ -z "$AIVEN_SERVICE_NAME" ]; then
    echo "❌ ERROR: Database credentials not set!"
    echo "📋 Required environment variables:"
    echo "   export DB_USER=\"your_database_user\""
    echo "   export DB_PASSWORD=\"your_database_password\""
    echo "   export AIVEN_SERVICE_NAME=\"your_service_name\""
    exit 1
fi

# Test Aiven service status
echo "Checking Aiven service status..."
avn service get "$AIVEN_SERVICE_NAME" --format json | jq '.state'

# Get connection details and test
echo "Extracting connection details..."
SERVICE_URI=$(avn service get "$AIVEN_SERVICE_NAME" --format json | jq -r '.service_uri')
DB_HOST=$(echo "$SERVICE_URI" | awk -F'[@:] '{print $4}')
DB_PORT=$(echo "$SERVICE_URI" | awk -F'[@:] '{print $5}')
DB_NAME=$(echo "$SERVICE_URI" | awk -F'[/] '{print $4}')

echo "Testing database connectivity to $DB_HOST:$DB_PORT/$DB_NAME..."

# Test basic connectivity
pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"

# Test full connection with psql
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();"
```

**Schema Deployment Failed**
```bash
# REQUIREMENT: Database credentials must be set as environment variables
if [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ] || [ -z "$AIVEN_SERVICE_NAME" ]; then
    echo "❌ ERROR: Database credentials not set!"
    echo "📋 Required environment variables:"
    echo "   export DB_USER=\"your_database_user\""
    echo "   export DB_PASSWORD=\"your_database_password\""
    echo "   export AIVEN_SERVICE_NAME=\"your_service_name\""
    exit 1
fi

# Get connection details
echo "Getting connection details..."
SERVICE_URI=$(avn service get "$AIVEN_SERVICE_NAME" --format json | jq -r '.service_uri')
DB_HOST=$(echo "$SERVICE_URI" | awk -F'[@:] '{print $4}')
DB_PORT=$(echo "$SERVICE_URI" | awk -F'[@:] '{print $5}')
DB_NAME=$(echo "$SERVICE_URI" | awk -F'[/] '{print $4}')

# Check SQL syntax for all schema files
echo "Checking SQL syntax for schema files..."
for file in schema/*.sql; do
    echo "Checking $file..."
    psql --quiet -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$file" --single-transaction
done

# Verify schema files are in correct order
echo "Verifying schema file order..."
ls -la schema/0*.sql schema/1*.sql schema/2*.sql

# Check database user permissions
echo "Checking database user permissions..."
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "\du"

# Test table creation permissions
echo "Testing table creation permissions..."
PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "CREATE TABLE test_table (id INT); DROP TABLE test_table;"
```

### Debug Commands

```bash
# Check workflow status
gh run list --workflow="Deploy Database" --limit=5

# View failed job logs
gh run view <run-id> --log-failed

# Check Aiven service status
avn service get <service-name>

# Test database connection
psql -h <host> -p <port> -U <user> -d <database> -c "SELECT version();"
```

## Environment Variables Required

The following GitHub secrets must be configured:
- `AIVEN_TOKEN` - Aiven personal access token
- `AIVEN_PROJECT_NAME` - Aiven project name
- `AIVEN_SERVICE_NAME` - PostgreSQL service name
- `AIVEN_DB_USER` - Database username
- `AIVEN_DB_PASSWORD` - Database password

## Deployment Rollback

If deployment fails or causes issues:

### Option A: Revert Schema Changes
```bash
# Identify problematic commit
git log --oneline develop

# Revert the commit
git revert <commit-hash>
git push origin develop
```

### Option B: Manual Database Restore
```bash
# Connect to database and manually undo changes
psql -h <host> -p <port> -U <user> -d <database>

# Drop and recreate tables if needed
DROP TABLE IF EXISTS shot_history CASCADE;
-- Repeat for other problematic tables
```

## Best Practices

### Before Deployment
- Test schema changes locally first
- Ensure all SQL files are syntactically correct
- Verify database user has required permissions
- Check that Aiven service is healthy

### After Deployment
- Verify all tables were created correctly
- Test basic database operations
- Monitor Aiven service metrics
- Update documentation if needed

### Security
- Never commit secrets to the repository
- Use least privilege database permissions
- Rotate Aiven tokens regularly
- Monitor deployment logs for unusual activity

## Automation

### Create a Deployment Script
```bash
#!/bin/bash
# deploy-to-dev.sh

echo "🚀 Deploying to development environment..."

# Trigger deployment
gh workflow run "Deploy Database" --field environment=development

# Wait for deployment to complete
echo "⏳ Waiting for deployment to start..."
sleep 10

# Get the latest run
RUN_ID=$(gh run list --workflow="Deploy Database" --limit=1 --json databaseId --jq '.[0].databaseId')

# Monitor deployment
echo "📊 Monitoring deployment progress..."
gh run watch "$RUN_ID"

echo "✅ Deployment completed!"
```

## Related Documentation

- [Aiven Deployment Setup Guide](../docs/aiven-deployment-setup.md)
- [Database Schema Documentation](../schema/00-schema.sql)
- [GitHub Actions Workflow](../.github/workflows/deploy.yml)
