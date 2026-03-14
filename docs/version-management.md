# Automated Version Management Workflow

## Description
This workflow provides automated version management for the Espresso ML Database project. It analyzes git commits to determine version changes, updates Dockerfile labels, generates release documentation, and integrates with deployment workflow.

## How It Works

### 1. Version Analysis
- **Commit Analysis**: Scans git commits since last tag to identify changes
- **Version Type Detection**: Determines if changes are MAJOR, MINOR, or PATCH
- **Semantic Versioning**: Follows conventional commit message format

### 2. Version Bumping
- **Major**: Breaking changes (BREAKING CHANGE, breaking, major, !:)
- **Minor**: New features (feat, feature, add, new, :)
- **Patch**: Fixes (fix, bug, patch, update, :)

### 3. Documentation Generation
- **Release Notes**: Auto-generated markdown with commit details
- **Changelog**: Updates CHANGELOG.md with new version
- **Dockerfile**: Updates version label automatically

### 4. Git Integration
- **Version Tag**: Creates and pushes git tag
- **Version Commit**: Commits version changes to develop branch

## When It Runs

The version management workflow triggers automatically when:
- Code is merged to **develop** branch
- **CI pipeline** completes successfully
- **Only runs on develop branch** (not main/production)

## Workflow Steps

### Step 1: Version Analysis
```bash
# Analyzes commits since last tag
./scripts/version-manager.sh main
```

**Output:**
- 🎯 Next version: 1.2.3 (minor release)
- 🚨 Breaking changes: 0
- ✨ Features: 2
- 🐛 Fixes: 1

### Step 2: File Updates
- **Dockerfile**: Updates `LABEL version="x.y.z"`
- **Release Notes**: Creates `release-notes/vx.y.z.md`
- **Changelog**: Updates `CHANGELOG.md`

### Step 3: Git Operations
- **Commit**: `chore: bump version to 1.2.3`
- **Tag**: `v1.2.3` with release notes
- **Push**: Updates develop branch

### Step 4: Artifact Upload
- **Release Artifacts**: Uploads all generated files
- **Versioned Storage**: Artifacts stored by version number

## Integration with Deployment

The deploy workflow uses version management outputs:

### Version Management Outputs
```yaml
outputs:
  version: ${{ steps.version.outputs.version }}
  version-type: ${{ steps.version.outputs.version-type }}
  release-notes: ${{ steps.version.outputs.release-notes }}
```

### Deployment Integration
```yaml
deploy-development:
  needs: version-management
  env:
    DEPLOY_VERSION: ${{ needs.version-management.outputs.version }}
```

### Version-Aware Deployment
- **Schema Deployment**: Shows version in logs
- **Status Updates**: Includes version in deployment status
- **Notifications**: Version-aware deployment messages

## Manual Usage

### Local Version Management
```bash
# Run version analysis locally
./scripts/version-manager.sh main

# Only analyze commits
./scripts/version-manager.sh analyze

# Only update files
./scripts/version-manager.sh update-files
```

### Manual Deployment Trigger
```bash
# Trigger deployment with specific version
gh workflow run "Deploy Database" --field environment=development
```

## File Structure

### Created Files
```
release-notes/
├── v1.2.3.md          # Release notes for this version
CHANGELOG.md                 # Project changelog
Dockerfile                   # Updated with new version
scripts/
└── version-manager.sh         # Version management script
```

### Git Tags
```
v0.1.0    # Initial release
v1.0.0    # First stable version
v1.1.0    # Feature additions
v1.1.2    # Bug fixes
v1.2.0    # Feature additions
v1.2.3    # Current version (auto-generated)
```

## Commit Message Format

### Supported Patterns
- **feat**: New features (triggers MINOR version)
- **fix**: Bug fixes (triggers PATCH version)
- **BREAKING CHANGE**: Breaking changes (triggers MAJOR version)
- **!**: Breaking changes alternative (triggers MAJOR version)

### Examples
```bash
# Feature addition
git commit -m "feat: add user authentication system"

# Bug fix
git commit -m "fix: resolve database connection timeout"

# Breaking change
git commit -m "BREAKING CHANGE: remove deprecated user table"

# Alternative breaking syntax
git commit -m "!: change user ID format to UUID"
```

## Environment Variables Required

### For Local Usage
```bash
export AIVEN_TOKEN="your_aiven_token"
export DB_USER="avnadmin"
export DB_PASSWORD="your_database_password"
export AIVEN_SERVICE_NAME="your_service_name"
```

### For GitHub Actions
- `AIVEN_TOKEN`: Aiven personal access token
- `AIVEN_PROJECT_NAME`: Aiven project name
- `AIVEN_SERVICE_NAME`: PostgreSQL service name
- `AIVEN_DB_USER`: Database username
- `AIVEN_DB_PASSWORD`: Database password

## Troubleshooting

### Version Detection Issues
```bash
# Check if tags exist
git tag --list

# Force specific version
./scripts/version-manager.sh --version 1.2.3

# Debug version analysis
./scripts/version-manager.sh --debug
```

### Deployment Issues
```bash
# Check version management job
gh run list --workflow="Deploy Database" --limit=5

# View version outputs
gh run view <run-id> --job version-management

# Check deployment dependencies
gh run view <run-id> | grep "needs version-management"
```

### File Permission Issues
```bash
# Make script executable
chmod +x scripts/version-manager.sh

# Check file permissions
ls -la scripts/version-manager.sh

# Test script locally
./scripts/version-manager.sh --help
```

## Best Practices

### Commit Messages
- Use conventional commit format
- Be descriptive in commit messages
- Reference issues when applicable
- Use BREAKING CHANGE for breaking changes

### Version Management
- Let automation handle version bumping
- Review generated release notes
- Test version changes locally

### Integration
- Ensure CI passes before version bump
- Review deployment logs after version changes
- Keep CHANGELOG.md up to date

## Advanced Usage

### Custom Version Logic
```bash
# Override automatic detection
./scripts/version-manager.sh --version-type major --version 2.0.0

# Skip git operations
./scripts/version-manager.sh --no-git

# Custom release notes
./scripts/version-manager.sh --notes "Custom release message"
```

### Integration with CI/CD
The version management system integrates seamlessly with:
- **GitHub Actions**: Automated workflows
- **Aiven Deployment**: Version-aware deployments
- **Docker Registry**: Versioned container images
- **Release Process**: Complete automation pipeline

## Monitoring

### Version Tracking
Monitor version progression through:
- Git tags in repository
- Docker image labels
- GitHub release artifacts
- Deployment notifications

### Quality Assurance
- Release notes accuracy
- Version bump correctness
- Documentation completeness
- Integration testing

This automated version management system ensures consistent, traceable releases with proper documentation and deployment integration.
