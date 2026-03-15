# CI Failure Analysis - Run 23083119016

## Run Information
- **Run ID**: 23083119016
- **Repository**: otnipid/espresso-ai-db
- **Branch**: develop
- **Workflow**: Deploy Database
- **Timestamp**: 2026-03-14T07:16:20Z

## Failed Jobs
### Job: Deploy to Development (Aiven)
- **Status**: ❌ Failed
- **Failed Step**: Deploy Schema to Aiven PostgreSQL
- **Error**: EOFError: EOF when reading a line
- **Root Cause**: avn user login --token command expects interactive input

## Error Details
The command `avn user login --token $AIVEN_AUTH_TOKEN` is prompting for username/email input instead of accepting the token directly. This suggests the command syntax is incorrect for token-based authentication.
