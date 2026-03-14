#!/bin/bash
# version-manager.sh - Automated version management for Espresso ML Database
# Analyzes git commits to determine version type and manages releases

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKERFILE_PATH="Dockerfile"
RELEASE_NOTES_DIR="release-notes"
CHANGELOG_FILE="CHANGELOG.md"

echo -e "${BLUE}🏷️  Espresso ML Database Version Manager${NC}"
echo "=========================================="

# Function to get current version from Dockerfile
get_current_version() {
    if [ -f "$DOCKERFILE_PATH" ]; then
        grep -E "LABEL version=\"[0-9]+\.[0-9]+\.[0-9]+\"" "$DOCKERFILE_PATH" | sed -E 's/.*version=\"([0-9]+\.[0-9]+\.[0-9]+)\".*/\1/' || echo "0.1.0"
    else
        echo "0.1.0"
    fi
}

# Function to get last version from git tags
get_last_version() {
    git describe --tags --abbrev=0 2>/dev/null || echo "v0.1.0"
}

# Function to analyze commits since last version
analyze_commits() {
    local last_tag=$1
    local version_type="patch"
    local breaking_changes=0
    local feature_count=0
    local fix_count=0
    
    echo -e "${YELLOW}📊 Analyzing commits since $last_tag${NC}"
    
    # Get commits since last tag
    local commits
    if [ "$last_tag" = "v0.1.0" ]; then
        commits=$(git log --oneline --all)
    else
        commits=$(git log --oneline "$last_tag"..HEAD)
    fi
    
    # Analyze each commit message
    while IFS= read -r commit; do
        local message=$(echo "$commit" | sed 's/^[^ ]* //')
        
        # Check for breaking changes
        if echo "$message" | grep -qi "BREAKING CHANGE\|breaking\|major\|!:"; then
            breaking_changes=1
            version_type="major"
        fi
        
        # Check for new features
        if echo "$message" | grep -qi "feat\|feature\|add\|new\|:"; then
            feature_count=$((feature_count + 1))
            if [ "$breaking_changes" -eq 0 ]; then
                version_type="minor"
            fi
        fi
        
        # Check for fixes
        if echo "$message" | grep -qi "fix\|bug\|patch\|update\|:"; then
            fix_count=$((fix_count + 1))
        fi
    done <<< "$commits"
    
    echo -e "   🚨 Breaking changes: $breaking_changes"
    echo -e "   ✨ Features: $feature_count"
    echo -e "   🐛 Fixes: $fix_count"
    
    echo "$version_type"
}

# Function to calculate next version
calculate_next_version() {
    local current_version=$1
    local version_type=$2
    
    IFS='.' read -ra version_parts <<< "$current_version"
    local major=${version_parts[0]}
    local minor=${version_parts[1]}
    local patch=${version_parts[2]}
    
    case $version_type in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
    esac
    
    echo "${major}.${minor}.${patch}"
}

# Function to update Dockerfile version
update_dockerfile_version() {
    local new_version=$1
    
    echo -e "${GREEN}📝 Updating Dockerfile to version $new_version${NC}"
    
    # Backup original Dockerfile
    cp "$DOCKERFILE_PATH" "${DOCKERFILE_PATH}.backup"
    
    # Update version label using portable method
    perl -i -pe 's/LABEL version="\d+\.\d+\.\d+"/LABEL version="'$new_version'"/g' "$DOCKERFILE_PATH"
    
    echo -e "${GREEN}✅ Dockerfile updated${NC}"
}

# Function to generate release notes
generate_release_notes() {
    local version=$1
    local version_type=$2
    local last_tag=$3
    
    echo -e "${GREEN}📋 Generating release notes${NC}"
    
    # Create release notes directory
    mkdir -p "$RELEASE_NOTES_DIR"
    
    local release_file="$RELEASE_NOTES_DIR/v${version}.md"
    
    cat > "$release_file" << EOF
# Release Notes v$version

**Release Type:** $version_type
**Date:** $(date +%Y-%m-%d)

## Changes

EOF

    # Add commits since last tag
    if [ "$last_tag" = "v0.1.0" ]; then
        git log --oneline --all --pretty=format:"- %s" >> "$release_file"
    else
        git log --oneline "$last_tag"..HEAD --pretty=format:"- %s" >> "$release_file"
    fi
    
    echo -e "${GREEN}✅ Release notes generated: $release_file${NC}"
    echo "$release_file"
}

# Function to generate changelog
update_changelog() {
    local version=$1
    local version_type=$2
    
    echo -e "${GREEN}📝 Updating changelog${NC}"
    
    # Add to changelog
    if [ ! -f "$CHANGELOG_FILE" ]; then
        cat > "$CHANGELOG_FILE" << EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]
EOF
    fi
    
    # Add new version entry using portable method
    local temp_file="${CHANGELOG_FILE}.tmp"
    perl -i -pe 's/## \[Unreleased\]/## \[Unreleased\]\n\n## [$version] - '"$(date +%Y-%m-%d)"'\n\n**$version_type release**/g' "$CHANGELOG_FILE" > "$temp_file"
    mv "$temp_file" "$CHANGELOG_FILE"
    
    echo -e "${GREEN}✅ Changelog updated${NC}"
}

# Function to create git tag and push
create_release() {
    local version=$1
    local release_file=$2
    
    echo -e "${BLUE}🚀 Creating release v$version${NC}"
    
    # Create git tag
    git tag -a "v$version" -m "Release v$version"
    
    # Push tag
    git push origin "v$version"
    
    echo -e "${GREEN}✅ Git tag v$version created and pushed${NC}"
}

# Main execution
main() {
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}❌ Error: Not in a git repository${NC}"
        exit 1
    fi
    
    # Get current version
    local current_version=$(get_current_version)
    echo -e "${BLUE}📍 Current version: $current_version${NC}"
    
    # Get last version
    local last_tag=$(get_last_version)
    echo -e "${BLUE}🏷️  Last version: $last_tag${NC}"
    
    # Analyze commits
    local version_type=$(analyze_commits "$last_tag")
    
    # Calculate next version
    local next_version=$(calculate_next_version "$current_version" "$version_type")
    echo -e "${GREEN}🎯 Next version: $next_version ($version_type release)${NC}"
    
    # Update Dockerfile
    update_dockerfile_version "$next_version"
    
    # Generate release notes
    local release_file=$(generate_release_notes "$next_version" "$version_type" "$last_tag")
    
    # Update changelog
    update_changelog "$next_version" "$version_type"
    
    # Create release
    create_release "$next_version" "$release_file"
    
    # Output summary
    echo ""
    echo -e "${GREEN}🎉 Version management completed!${NC}"
    echo "=========================================="
    echo -e "📦 Version: $next_version"
    echo -e "📋 Type: $version_type"
    echo -e "📄 Release notes: $release_file"
    echo -e "📝 Dockerfile updated"
    echo -e "🏷️  Git tag created"
    echo ""
    echo -e "${YELLOW}💡 Next steps:${NC}"
    echo "1. Review and commit the changes:"
    echo "   git add ."
    echo "   git commit -m \"chore: bump version to $next_version\""
    echo "2. Push changes:"
    echo "   git push origin develop"
    echo ""
    echo -e "${BLUE}📋 Files created/updated:${NC}"
    echo "  - $release_file"
    echo "  - $CHANGELOG_FILE"
    echo "  - ${DOCKERFILE_PATH}"
}

# Run main function
main "$@"
