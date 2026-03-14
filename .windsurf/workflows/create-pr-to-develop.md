# Create Pull Request to Develop Branch Workflow

Pretend you are a DevOps Engineer. This workflow provides a systematic approach for DevOps Engineers to create pull requests from feature branches to the develop branch, ensuring proper validation, testing, and deployment readiness.

## When to Use This Workflow

Use this workflow when you have completed development on a feature branch and need to merge it into the develop branch for integration testing and staging deployment.

## Prerequisites

- Feature branch is up-to-date with latest develop branch
- All automated tests are passing on the feature branch
- Code follows project standards and has been reviewed
- Documentation is updated if applicable
- No merge conflicts with develop branch

## Steps

### Step 1: Validate Branch Status
Ensure your feature branch is ready for PR creation:
```bash
# Check current branch
git branch --show-current

# Verify branch is up-to-date
git fetch origin
git status

# Check for any uncommitted changes
git status --porcelain
```

### Step 2: Sync with Develop Branch
Update develop branch and check for conflicts:
```bash
# Checkout and update develop branch
git checkout develop
git pull origin develop

# Return to feature branch
git checkout feature/automated-aiven-deployment

# Merge latest develop into feature branch
git merge develop

# Resolve any conflicts if they exist
# (See Conflict Resolution section below)
```

### Step 3: Run Final Validation
Execute comprehensive testing before PR creation:
```bash
# Run all tests
npm test  # or appropriate test command

# Run linting
npm run lint  # or appropriate lint command

# Check build process
npm run build  # or appropriate build command

# Verify application starts correctly
npm run start  # if applicable
```

### Step 4: Create Pull Request
Create the PR with proper documentation:
```bash
# Create PR using GitHub CLI (preferred)
gh pr create --base develop --title "feat: implement automated Aiven deployment" --body "$(cat <<EOF
## Summary
Implements comprehensive automated deployment pipeline for Aiven integration with enhanced CI/CD workflows.

## Changes Made
- Enhanced deployment workflows with safety checks and rollbacks
- Added development workflow automation
- Updated documentation for Aiven deployment setup
- Added utility scripts for deployment automation

## Testing
- All automated tests passing
- CI/CD workflows validated
- Documentation reviewed and updated
- Integration testing completed

## Deployment Impact
- Low risk deployment with rollback capabilities
- No breaking changes to existing functionality
- Requires environment variable updates for Aiven integration

## Checklist
- [ ] Code follows project standards
- [ ] Tests are passing
- [ ] Documentation is updated
- [ ] No merge conflicts
- [ ] Security review completed
- [ ] Performance impact assessed

EOF
)"

# Alternative: Create PR via GitHub web interface
# Visit: https://github.com/otnipid/espresso-ai-db/pull/new/feature/automated-aiven-deployment
```

### Step 5: Configure PR Settings
Set up proper PR configuration:
```bash
# Add required reviewers
gh pr edit --add-reviewer "team-lead,devops-team"

# Add labels for proper categorization
gh pr edit --add-label "feature,deployment,ci-cd"

# Set milestone if applicable
gh pr edit --milestone "v1.2.0"

# Link to project board items
gh pr edit --add-project "espresso-ai-db"
```

### Step 6: Monitor PR Validation
Track automated checks and reviews:
```bash
# Check PR status
gh pr view --web

# Monitor CI/CD pipeline
gh pr checks

# Watch for review comments
gh pr view --comments
```

### Step 7: Address Feedback
Handle any review comments or failed checks:
```bash
# Make necessary changes based on feedback
# Commit and push updates
git add .
git commit -m "fix: address PR feedback - improve deployment safety"
git push origin feature/automated-aiven-deployment
```

### Step 8: Final Approval and Merge
Once all checks pass and reviews are approved:
```bash
# Verify all checks are green
gh pr checks

# Request final review if needed
gh pr edit --add-reviewer "release-manager"

# Merge PR (use squash merge for clean history)
gh pr merge --squash --delete-branch
```

## Conflict Resolution

### If Merge Conflicts Occur:
```bash
# Identify conflicted files
git status

# Resolve conflicts manually
# Edit conflicted files and remove conflict markers
# <<<<<<< HEAD
# // develop branch changes
# =======
# // feature branch changes
# >>>>>>> feature/automated-aiven-deployment

# Stage resolved files
git add <resolved-files>

# Continue merge
git merge --continue

# Test after conflict resolution
npm test
```

### Common Conflict Scenarios:
- **Workflow files**: Manual resolution required for YAML syntax
- **Documentation**: Merge both sets of changes
- **Package dependencies**: Prefer newer versions, test compatibility
- **Configuration files**: Follow environment-specific patterns

## Quality Gates

### Automated Checks Must Pass:
- [ ] All unit tests passing (>95% coverage)
- [ ] Integration tests passing
- [ ] Code linting and formatting checks
- [ ] Security vulnerability scan
- [ ] Dependency vulnerability check
- [ ] Build process successful
- [ ] Docker image builds successfully

### Manual Review Requirements:
- [ ] Code review by at least one team member
- [ ] DevOps review for infrastructure changes
- [ ] Security review for sensitive changes
- [ ] Documentation review for user-facing changes

## Post-Merge Activities

### After Successful Merge:
```bash
# Delete local feature branch
git branch -d feature/automated-aiven-deployment

# Clean up remote tracking branch
git remote prune origin

# Update local develop branch
git checkout develop
git pull origin develop

# Tag release if ready
git tag -a v1.2.0 -m "Release v1.2.0: Automated Aiven deployment"
git push origin v1.2.0
```

### Deployment Planning:
- Monitor staging deployment after merge
- Prepare production deployment checklist
- Schedule release window if needed
- Notify stakeholders of upcoming changes

## Emergency Rollback

### If Issues Detected After Merge:
```bash
# Identify problematic commit
git log --oneline -10

# Revert merge commit
git revert -m 1 <merge-commit-hash>

# Push revert to develop
git push origin develop

# Create hotfix branch if needed
git checkout -b hotfix/fix-deployment-issue
# Make necessary fixes
# Follow same PR process for hotfix
```

## Best Practices

### ✅ Do:
- Keep PRs focused and atomic
- Write clear, descriptive commit messages
- Include comprehensive testing
- Document breaking changes
- Use semantic versioning
- Follow security best practices
- Monitor deployment metrics

### ❌ Don't:
- Merge without proper testing
- Ignore security scans
- Skip documentation updates
- Force merge without resolving conflicts
- Merge during peak hours without coordination
- Skip rollback planning

## Automation Opportunities

This workflow can be enhanced with:
- Automated PR templates
- Pre-commit hooks for validation
- Automated testing on PR creation
- Automated security scanning
- Automated deployment to staging
- Automated rollback triggers
- Integration with project management tools

## Monitoring and Alerts

Set up monitoring for:
- PR creation and merge rates
- Time-to-merge metrics
- Test failure rates
- Deployment success rates
- Rollback frequency
- Security scan results
