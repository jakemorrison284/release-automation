#!/bin/bash
# Script to automate the release process with build, test, lint, and error notifications

set -e  # Exit immediately if a command exits with a non-zero status

# Default variables
VERSION="$(date +%Y%m%d%H%M%S)"
LOGFILE="release.log"
ERRORLOGFILE="release_error.log"
EMAIL_NOTIFICATION="youremail@example.com"  # Set your notification email here
NOTIFY_CHANNEL="email"  # Default notification channel: email
VERBOSE=1  # Verbosity level: 0=quiet, 1=normal, 2=verbose
EXIT_ON_ERROR=1  # Exit on error flag

usage() {
    echo "Usage: $0 [-v version] [-e email] [-c notify_channel] [-l logfile] [-q]"
    echo "  -v version           Specify version (default: timestamp)"
    echo "  -e email             Email address for notifications"
    echo "  -c notify_channel    Notification channel: email, slack"
    echo "  -l logfile           Log file path (default: release.log)"
    echo "  -q                   Quiet mode (no output except errors)"
    exit 1
}

# Parse command line options
while getopts ":v:e:c:l:q" opt; do
    case $opt in
        v) VERSION="$OPTARG" ;;
        e) EMAIL_NOTIFICATION="$OPTARG" ;;
        c) NOTIFY_CHANNEL="$OPTARG" ;;
        l) LOGFILE="$OPTARG" ;;
        q) VERBOSE=0 ;;
        *) usage ;;
    esac
done

# Logging function with levels
log() {
    local level="$1"
    local message="$2"
    local timestamp="$(date +%Y-%m-%d %H:%M:%S)"
    if [[ $VERBOSE -ge 1 || "$level" == "ERROR" ]]; then
        echo "$timestamp - $level - $message" | tee -a "$LOGFILE"
    fi
    if [[ "$level" == "ERROR" ]]; then
        echo "$timestamp - $level - $message" >> "$ERRORLOGFILE"
    fi
}

# Notification function
notify_error() {
    local message="$1"
    log "ERROR" "$message"
    case $NOTIFY_CHANNEL in
        email)
            # Send email notification on error (requires mailutils or similar configured)
            echo "$message" | mail -s "Release Automation Error - Version $VERSION" "$EMAIL_NOTIFICATION"
            ;;
        slack)
            # Placeholder for Slack notification (requires webhook URL in environment variable SLACK_WEBHOOK_URL)
            if [ -z "$SLACK_WEBHOOK_URL" ]; then
                log "ERROR" "Slack webhook URL not set. Cannot send Slack notification."
            else
                payload="{\"text\":\"Release Automation Error - Version $VERSION: $message\"}"
                curl -X POST -H 'Content-type: application/json' --data "$payload" "$SLACK_WEBHOOK_URL"
            fi
            ;;
        *)
            log "ERROR" "Unknown notification channel: $NOTIFY_CHANNEL"
            ;;
    esac
}

# Enhanced error handler
error_handler() {
    local exit_code=$?
    local last_command=${BASH_COMMAND}
    notify_error "Command '$last_command' exited with code $exit_code at line $LINENO."
    if [[ $EXIT_ON_ERROR -eq 1 ]]; then
        exit $exit_code
    fi
}

# Trap errors to send notification
trap error_handler ERR

log "INFO" "Starting the build process for version $VERSION..."

# Build commands (example using make)
if ! make build; then
    notify_error "Build failed!"
    exit 1
fi

log "INFO" "Build completed successfully."

# Run linting
log "INFO" "Starting linting..."
if ! make lint; then
    notify_error "Linting failed!"
    exit 1
fi
log "INFO" "Linting completed successfully."

# Run tests
log "INFO" "Starting tests..."
if ! make test; then
    notify_error "Tests failed!"
    exit 1
fi
log "INFO" "Tests completed successfully."

log "INFO" "Release process for version $VERSION completed successfully!"
