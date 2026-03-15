---
trigger: always_on
---
# Project Rules

## Code Quality
- Prioritize idempotency, modularity, and reusability in schema designs
- Always document dependencies and relationships between tables
- Prefer explicit types and avoid magic numbers

## Shell Scripting Standards
- Small functions (<30 lines) with clear documentation
- Always include documentation for new functions and classes including:
  - A description of the function
  - Parameters
  - Return value
- No deep nesting
- Use proper error handling with exit codes
- Test commands in isolation before integration

## CI/CD Code Style
- Use consistent variable naming across workflow steps
- Set environment variables at appropriate scope (job vs step level)
- Add debug output for troubleshooting but never expose secrets
- Use proper shell syntax for environment variables and command substitution
- Implement timeout logic for external service connections

## Database Schema Standards
- Use descriptive table and column names
- Include proper constraints and indexes
- Document table relationships and dependencies
- Use migration-friendly schema changes