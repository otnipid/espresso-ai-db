---
trigger: always_on
---
# Authentication and Security Rules

## Environment Variable Management
- Use consistent naming conventions across all steps
- Set sensitive variables at job level, not step level
- Never log or echo secret values in debug output
- Use `AVN_AUTH_TOKEN` for Aiven CLI authentication
- Verify variable names match exactly (case-sensitive)

## Secret Handling Best Practices
- Always test authentication before functional operations
- Use service-specific environment variables when available
- Add debug output to verify authentication status
- Test with `avn user info` before service operations
- Remove redundant environment variable declarations

## API Integration Rules
- Never include 4-byte Unicode characters in API descriptions
- Use proper error handling for API validation failures
- Test API calls with minimal payloads first
- Use appropriate content types and headers
- Handle rate limiting and authentication errors gracefully

## Connection Security
- Always use SSL/TLS for database connections
- Set `PGSSLMODE=require` as environment variable
- Never hardcode credentials in workflow files
- Use GitHub secrets for all sensitive data
- Verify connection strings before use

## Debugging Security
- Mask sensitive values in debug output
- Use generic success/failure messages in status updates
- Never expose connection details in logs
- Test authentication with read-only operations first
- Use environment variables for all configuration
