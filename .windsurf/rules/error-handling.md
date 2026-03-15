---
trigger: always_on
---
# Error Handling and Troubleshooting Rules

## Systematic Debugging Methodology
- Always start with the most recent failure logs
- Use `gh run view <run-id> --log-failed` to focus on errors
- Check environment variables and secrets first
- Verify authentication before troubleshooting functionality
- Address root cause instead of symptoms

## Error Resolution Priority
1. **Shell Syntax Errors** - Fix before addressing functionality
2. **Authentication Issues** - Resolve before database operations  
3. **Connection Problems** - Fix before schema deployment
4. **Logic Errors** - Address after infrastructure is working
5. **Performance Issues** - Optimize after functionality is confirmed

## Debugging Output Guidelines
- Add debug output to identify variable values and connection issues
- Use generic success/failure messages in status updates
- Never expose sensitive connection details in logs
- Test individual commands in isolation before integrating
- Use minimal, focused changes rather than large refactors

## Common Error Patterns
- **Environment Variable Mismatches** - Check case-sensitive names
- **Authentication Failures** - Verify token format and permissions
- **Connection Timeouts** - Add proper timeout logic and retry mechanisms
- **URI Parsing Errors** - Use simple sed patterns instead of complex regex
- **Unicode Validation Errors** - Remove 4-byte characters from API calls

## Testing and Validation
- Always test deployment after fixes
- Monitor with `gh run watch` for real-time feedback
- Verify all steps complete successfully
- Check both authentication and functionality
- Use automated verification when possible

## Incremental Problem Solving
- Make one change at a time
- Test each change individually
- Commit working states frequently
- Roll back to last known good state when needed
- Document successful patterns for future reference
