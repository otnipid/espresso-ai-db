---
trigger: always_on
---
# CI/CD Debugging Rules

## Systematic Debugging Approach
- Always start with the most recent failure logs
- Use `gh run view <run-id> --log-failed` to focus on errors
- Check environment variables and secrets first
- Verify authentication before troubleshooting functionality

## GitHub Actions Best Practices
- Set environment variables at job level, not step level when possible
- Use `AVIENN_AUTH_TOKEN` for Aiven CLI, not `AVN_AUTH_TOKEN`
- Never include 4-byte Unicode characters in GitHub API descriptions
- Use explicit authentication commands when environment variables aren't recognized
- Add debug output to identify variable values and connection issues

## Database Connection Debugging
- Always test database readiness with `pg_isready` before schema deployment
- Use `PGSSLMODE=require` as environment variable, not command prefix
- Parse connection URIs with simple sed patterns, not complex regex
- Use `AIVEN_DB_USER` variable instead of parsing from URI when available
- Add timeout logic for database readiness checks

## Variable and Secret Management
- Verify secret names match exactly (case-sensitive)
- Use consistent variable names across all steps
- Test authentication with `avn user info` before service operations
- Add debug output to verify variable values are correct

## Error Resolution Strategy
- Fix shell syntax errors before addressing functionality
- Resolve authentication issues before database operations
- Test individual commands in isolation before integrating
- Use minimal, focused changes rather than large refactors

## URI Parsing and Connection Strings
- Extract host: `sed -E 's#.*@([^:]+):.*#\1#'`
- Extract port: `sed -E 's#.*:([0-9]+)/.*#\1#'`
- Extract database: `sed -E 's#.*/([^/?]+).*#\1#'`
- Remove query parameters: `sed 's/?.*$//'`

## Aiven CLI Specific Rules
- Install via `pip install aiven-client` for reliability
- Use `AIVEN_AUTH_TOKEN` environment variable for authentication
- Test with `avn user info` before service operations
- Use `--format '{service_uri}'` for clean URI extraction
- Remove quotes with `tr -d '"'` for clean strings

## Workflow Structure
- Version management should run before deployment
- Upload artifacts, don't commit generated files
- Handle existing git tags gracefully
- Use workflow conditions to allow manual triggers
- Set proper job dependencies with `needs`

## Testing and Verification
- Always test deployment after fixes
- Monitor with `gh run watch` for real-time feedback
- Verify all steps complete successfully
- Check both authentication and functionality
