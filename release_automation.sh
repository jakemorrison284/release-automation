#!/bin/bash
# Enhanced script to automate the release process

set -e  # Exit immediately if a command exits with a non-zero status

# Load configuration
source config.env

# Default values
VERSION="$(date +%Y%m%d%H%M%S)"
BUILD_TYPE="npm"
LOGFILE="release.log"

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --version) VERSION="$2"; shift ;;  
        --build-type) BUILD_TYPE="$2"; shift ;;  
        *) echo "Unknown parameter passed: $1"; exit 1 ;;  
    esac
    shift
done

# Logging function
log() {
    echo "$(date +%Y-%m-%d %H:%M:%S) - $1" | tee -a $LOGFILE
}

# Build the release
log "Starting the build process for version $VERSION..."

# Build steps based on build type
case $BUILD_TYPE in
    npm) npm run build || log "Error: npm build failed!" ;;  
    make) make build || log "Error: make build failed!" ;;  
    *) log "Unknown build type: $BUILD_TYPE"; exit 1 ;;  
esac

log "Build for version $VERSION completed successfully!"

# Deployment steps (placeholder)
log "Deploying version $VERSION..."
# Replace with actual deployment command
# deploy_command || log "Deployment failed!"

# Notify team (placeholder)
# notify_team "Build for version $VERSION completed successfully!"

# Tagging the release
log "Tagging the release..."
git tag -a "v$VERSION" -m "Release version $VERSION"
git push origin "v$VERSION"