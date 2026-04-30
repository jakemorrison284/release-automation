#!/bin/bash
# Enhanced script to automate the release process with robustness and flexibility improvements

set -e  # Exit immediately if a command exits with a non-zero status

# Load configuration
source config.env

# Default values
VERSION_TYPE="$1"
LOGFILE="release.log"
EMAIL_RECIPIENTS=("dev-team@example.com" "qa-team@example.com")

# Logging function
log() {
    echo "$(date +%Y-%m-%d %H:%M:%S) - $1" | tee -a $LOGFILE
}

# Error handling function
handle_error() {
    log "Error occurred: $1"
    exit 1
}

trap 'handle_error "Script interrupted."' INT TERM

# Validate version type argument
if [ -z "$VERSION_TYPE" ]; then
    log "Please specify the version type (major, minor, patch)."
    exit 1
fi

# Function to increment version from versioning.yml using yq (YAML processor)
increment_version() {
    if ! command -v yq &> /dev/null; then
        handle_error "yq command not found, please install yq to parse YAML files."
    fi
    local current_version=$(yq e '.version' versioning.yml)
    local type="$1"
    IFS='.' read -r major minor patch <<< "$current_version"

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
            handle_error "Invalid version type. Use major, minor, or patch."
            ;;
    esac
    echo "$major.$minor.$patch"
}

# Function to generate changelog
generate_changelog() {
    git log --oneline $(git describe --tags --abbrev=0)..HEAD > CHANGELOG.md
}

# Function to create and push git tag
create_tag() {
    local new_version=$1
    git tag "v$new_version" || handle_error "Failed to create git tag."
    git push origin "v$new_version" || handle_error "Failed to push git tag."
}

# Function to send email notifications
send_notifications() {
    local version=$1
    local subject="New Release: v$version"
    local message="A new version v$version has been released. Please check the changelog for details."
    for recipient in "${EMAIL_RECIPIENTS[@]}"; do
        echo "$message" | mail -s "$subject" "$recipient" || log "Warning: Failed to send email to $recipient"
    done
}

# Main script execution
NEW_VERSION=$(increment_version "$VERSION_TYPE")
generate_changelog
create_tag "$NEW_VERSION"
send_notifications "$NEW_VERSION"

log "Release process complete. New version: v$NEW_VERSION"
