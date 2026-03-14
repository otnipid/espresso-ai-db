# Aiven Deployment Setup Guide

This guide explains how to configure the GitHub Actions workflow to deploy the Espresso ML database to Aiven PostgreSQL service.

## Prerequisites

1. **Aiven Account**: You have an active Aiven account
2. **Aiven PostgreSQL Service**: You've created a PostgreSQL service in Aiven
3. **GitHub Repository**: You have admin access to the repository

## Required GitHub Secrets

Add the following secrets to your GitHub repository settings:

### 1. Aiven Authentication
- **`AIVEN_AUTH_TOKEN`**: Your Aiven personal access token
  - How to get: Go to Aiven Console → Account → Access tokens → Create new token
  - Required permissions: `service:read`, `service:write`

### 2. Aiven Service Details
- **`AIVEN_PROJECT_NAME`**: Your Aiven project name
  - Example: `espresso-ml-dev`
  - How to get: Aiven Console → Projects → Copy project name

- **`AIVEN_SERVICE_NAME`**: Your PostgreSQL service name
  - Example: `espresso-postgres-dev`
  - How to get: Aiven Console → Your project → Services → Copy service name

### 3. Database Credentials
- **`AIVEN_DB_USER`**: Database username
  - Usually the default user created by Aiven
  - Example: `avnadmin`

- **`AIVEN_DB_PASSWORD`**: Database password
  - The password for your database user
  - How to get: Aiven Console → Your service → Users tab

## How to Add GitHub Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret from the list above

## Deployment Trigger

The deployment to Aiven will be automatically triggered when:

1. **Merge to develop branch**: When code is merged to the `develop` branch
2. **Manual dispatch**: You can manually trigger the deployment from GitHub Actions tab

## Deployment Process

The workflow will:

1. **Authenticate with Aiven** using your token
2. **Get service connection details** from Aiven
3. **Deploy schema files** in order (00-schema.sql, 01-extensions.sql, etc.)
4. **Run health checks** to verify the deployment
5. **Update deployment status** in GitHub

## Verification

After deployment, you can verify by:

1. **Check GitHub Actions logs** for deployment status
2. **Connect to Aiven PostgreSQL** to verify tables were created
3. **Run the health check queries** manually in your database

## Troubleshooting

### Common Issues

**Authentication Failed**
- Check that `AIVEN_AUTH_TOKEN` is correct and has proper permissions
- Ensure token hasn't expired

**Service Not Found**
- Verify `AIVEN_PROJECT_NAME` and `AIVEN_SERVICE_NAME` are correct
- Ensure the service exists and is running

**Database Connection Failed**
- Check `AIVEN_DB_USER` and `AIVEN_DB_PASSWORD`
- Verify the database user has proper permissions
- Ensure the PostgreSQL service is running

### Debug Steps

1. **Check GitHub Actions logs** for detailed error messages
2. **Verify Aiven service status** in Aiven Console
3. **Test connection manually** using psql with the same credentials
4. **Check schema files** for syntax errors

## Security Best Practices

1. **Use least privilege**: Only grant necessary permissions to the database user
2. **Rotate tokens regularly**: Update your Aiven token periodically
3. **Monitor access**: Check Aiven logs for unusual activity
4. **Use environment-specific secrets**: Don't use production secrets in development

## Example Configuration

```bash
# Example values (replace with your actual values)
AIVEN_AUTH_TOKEN="avn_xxxxx_your_token_here"
AIVEN_PROJECT_NAME="espresso-ml-dev"
AIVEN_SERVICE_NAME="espresso-postgres-dev"
AIVEN_DB_USER="avnadmin"
AIVEN_DB_PASSWORD="your_secure_password_here"
```

## Support

If you encounter issues:

1. Check the [Aiven documentation](https://docs.aiven.io/)
2. Review GitHub Actions logs for detailed error messages
3. Verify all secrets are correctly configured
4. Ensure your Aiven service is running and accessible
