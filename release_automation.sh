#!/bin/bash

# Enhanced script to automate the release process

set -e  # Exit immediately if a command exits with a non-zero status

# Load configuration from versioning.yml (you may need a YAML parser for this)
VERSION_FILE="versioning.yml"
CURRENT_VERSION=$(grep 'version:' $VERSION_FILE | awk '{print $2}')
VERSION_TYPE=$1  # Argument to specify the type of version increment (major, minor, patch)
EMAIL_RECIPIENTS=("dev-team@example.com" "qa-team@example.com")  # Recipients from versioning.yml

# Function to increment version based on type
increment_version() {
    local version=$1
    local type=$2
    IFS='.' read -r major minor patch <<< "$version"

    case $type in
        major)
            ((major++))
            minor=0
            patch=0
            ;; 
        minor)
            ((minor++))
            patch=0
            ;;
        patch)
            ((patch++))
            ;;
        *)
            echo "Invalid version type. Use major, minor, or patch."
            exit 1
            ;;
    esac

    echo "$major.$minor.$patch"
}

# Function to generate a changelog
generate_changelog() {
    git log --oneline $(git describe --tags --abbrev=0)..HEAD > CHANGELOG.md
}

# Function to create a new Git tag
create_tag() {
    local new_version=$1
    git tag "v$new_version"
    git push origin "v$new_version"
}

# Function to send email notifications
send_notifications() {
    local version=$1
    local subject="New Release: v$version"
    local message="A new version v$version has been released. Please check the changelog for details."
    
    for recipient in "${EMAIL_RECIPIENTS[@]}"; do
        echo "$message" | mail -s "$subject" "$recipient"
    done
}

# Main script execution
if [ -z "$VERSION_TYPE" ]; then
    echo "Please specify the version type (major, minor, patch)."
    exit 1
fi

NEW_VERSION=$(increment_version "$CURRENT_VERSION" "$VERSION_TYPE")
generate_changelog
create_tag "$NEW_VERSION"
send_notifications "$NEW_VERSION"

echo "Release process complete. New version: v$NEW_VERSION"