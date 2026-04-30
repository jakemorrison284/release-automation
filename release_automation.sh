#!/bin/bash
# Script to automate the release process with build, test, lint, and error notifications
# Enhanced with extended notification channels and parallel execution

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
    echo "  -c notify_channel    Notification channel: email, slack, sms, teams, pagerduty"
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

# Notification function with extended channels
notify_error() {
    local message="$1"
    log "ERROR" "$message"
    case $NOTIFY_CHANNEL in
        email)
            echo "$message" | mail -s "Release Automation Error - Version $VERSION" "$EMAIL_NOTIFICATION"
            ;;
        slack)
            if [ -z "$SLACK_WEBHOOK_URL" ]; then
                log "ERROR" "Slack webhook URL not set. Cannot send Slack notification."
            else
                payload="{\"text\":\"Release Automation Error - Version $VERSION: $message\"}"
                curl -s -X POST -H 'Content-type: application/json' --data "$payload" "$SLACK_WEBHOOK_URL"
            fi
            ;;
        sms)
            if [ -z "$SMS_API_URL" ] || [ -z "$SMS_API_KEY" ] || [ -z "$SMS_RECIPIENT" ]; then
                log "ERROR" "SMS API credentials or recipient not set. Cannot send SMS notification."
            else
                curl -s -X POST "$SMS_API_URL" \
                     -H "Authorization: Bearer $SMS_API_KEY" \
                     -H 'Content-Type: application/json' \
                     -d '{"to":"'$SMS_RECIPIENT'","message":"Release Automation Error - Version $VERSION: $message"}'
            fi
            ;;
        teams)
            if [ -z "$TEAMS_WEBHOOK_URL" ]; then
                log "ERROR" "Microsoft Teams webhook URL not set. Cannot send Teams notification."
            else
                payload="{\"text\":\"Release Automation Error - Version $VERSION: $message\"}"
                curl -s -X POST -H 'Content-type: application/json' --data "$payload" "$TEAMS_WEBHOOK_URL"
            fi
            ;;
        pagerduty)
            if [ -z "$PAGERDUTY_ROUTING_KEY" ]; then
                log "ERROR" "PagerDuty routing key not set. Cannot send PagerDuty notification."
            else
                payload="{\"routing_key\":\"$PAGERDUTY_ROUTING_KEY\",\"event_action\":\"trigger\",\"payload\":{\"summary\":\"Release Automation Error - Version $VERSION: $message\",\"source\":\"release_automation.sh\",\"severity\":\"error\"}}"
                curl -s -X POST -H 'Content-Type: application/json' --data "$payload" https://events.pagerduty.com/v2/enqueue
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

log "INFO" "Starting the build, lint, and test process for version $VERSION..."

# Run build, lint, and test in parallel
run_build() {
    if ! make build; then
        notify_error "Build failed!"
        exit 1
    fi
    log "INFO" "Build completed successfully."
}

run_lint() {
    if ! make lint; then
        notify_error "Linting failed!"
        exit 1
    fi
    log "INFO" "Linting completed successfully."
}

run_test() {
    if ! make test; then
        notify_error "Tests failed!"
        exit 1
    fi
    log "INFO" "Tests completed successfully."
}

# Execute all in background and wait for completion
run_build &
PID_BUILD=$!
run_lint &
PID_LINT=$!
run_test &
PID_TEST=$!

# Wait and check each
wait $PID_BUILD || exit 1
wait $PID_LINT || exit 1
wait $PID_TEST || exit 1

log "INFO" "Release process for version $VERSION completed successfully!"
