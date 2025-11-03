#!/bin/bash
# ==============================================================================
# service_monitor.sh
#
# A script to monitor specified services (e.g., httpd, mariadb) and
# automatically restart them if they are found to be inactive or failed.
# It logs all actions to a dedicated log file and to the system's logger.
# This script uses systemctl, which is the standard for managing services on modern Linux distributions
# Author: Vijay Kalvakolu
# ==============================================================================

# --- Configuration ---

# List of services to monitor. Add more services to this array as needed.
# For example: SERVICES=("httpd" "mariadb" "sshd")
SERVICES=("httpd" "mariadb")

# Log file for recording actions taken by this script.
# Ensure the user running this script has write permissions to this file/directory.
LOG_FILE="/var/log/service_monitor.log"

# --- Main Script ---

# Function to log messages to both a file and the system logger (syslog)
log_action() {
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %T") # e.g., 2023-10-27 14:30:00

    # Log to the specified log file
    echo "[$timestamp] $message" >> "$LOG_FILE"

    # Log to syslog with a 'user' facility and 'warning' priority
    # This will typically appear in /var/log/messages or be viewable with `journalctl`
    logger -p user.warn "ServiceMonitor: $message"
}

# Iterate over the list of services
for service in "${SERVICES[@]}"; do
    # Use `systemctl is-active --quiet` to check the service status.
    # It returns a 0 exit code if the service is active, and non-zero otherwise.
    if ! systemctl is-active --quiet "$service"; then
        # The service is not active (it could be stopped, failed, etc.)
        log_action "ALERT: Service '$service' is down. Attempting to restart..."

        # Attempt to restart the service
        systemctl restart "$service"

        # Give the service a moment to start up before checking its status again
        sleep 5

        # Verify if the restart was successful
        if systemctl is-active --quiet "$service"; then
            log_action "SUCCESS: Service '$service' was restarted successfully."
        else
            log_action "CRITICAL: Service '$service' FAILED to restart. Manual intervention required."
        fi
    fi
done
