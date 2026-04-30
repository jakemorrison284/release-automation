#!/bin/bash
# Script to automate the release process with build, test, lint, and error notifications

set -e  # Exit immediately if a command exits with a non-zero status

# Default variables
VERSION="$(date +%Y%m%d%H%M%S)"
LOGFILE="release.log"
EMAIL_NOTIFICATION="youremail@example.com"  # Set your notification email here
NOTIFY_CHANNEL="email"  # Default notification channel: email

usage() {
    echo "Usage: $0 [-v version] [-e email] [-c notify_channel]"
    echo "  -v version           Specify version (default: timestamp)"
    echo "  -e email             Email address for notifications"
    echo "  -c notify_channel    Notification channel: email, slack"
    exit 1
}

# Parse command line options
while getopts ":v:e:c:" opt; do
    case $opt in
        v) VERSION="$OPTARG" ;;
        e) EMAIL_NOTIFICATION="$OPTARG" ;;
        c) NOTIFY_CHANNEL="$OPTARG" ;;
        *) usage ;;
    esac
done

# Logging function
log() {
    echo "$(date +%Y-%m-%d %H:%M:%S) - $1" | tee -a $LOGFILE
}

# Notification function
notify_error() {
    local message="$1"
    log "ERROR: $message"
    case $NOTIFY_CHANNEL in
        email)
            # Send email notification on error (requires mailutils or similar configured)
            echo "$message" | mail -s "Release Automation Error - Version $VERSION" $EMAIL_NOTIFICATION
            ;;
        slack)
            # Placeholder for Slack notification (requires webhook URL in environment variable SLACK_WEBHOOK_URL)
            if [ -z "$SLACK_WEBHOOK_URL" ]; then
                log "Slack webhook URL not set. Cannot send Slack notification."
            else
                payload="{\"text\":\"Release Automation Error - Version $VERSION: $message\"}"
                curl -X POST -H 'Content-type: application/json' --data "$payload" $SLACK_WEBHOOK_URL
            fi
            ;;
        *)
            log "Unknown notification channel: $NOTIFY_CHANNEL"
            ;;
    esac
}

# Trap errors to send notification
trap 'notify_error "Release process failed at line $LINENO."' ERR

log "Starting the build process for version $VERSION..."

# Build commands (example using make)
if ! make build; then
    notify_error "Build failed!"
    exit 1
fi

log "Build completed successfully."

# Run linting
log "Starting linting..."
if ! make lint; then
    notify_error "Linting failed!"
    exit 1
fi
log "Linting completed successfully."

# Run tests
log "Starting tests..."
if ! make test; then
    notify_error "Tests failed!"
    exit 1
fi
log "Tests completed successfully."

log "Release process for version $VERSION completed successfully!"
