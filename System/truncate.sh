#!/bin/bash

# ==============================================================================
# truncate.sh
#
# A script to truncate (empty) specified log files while preserving their
# permissions and ownership. This is useful for managing log file sizes
# without stopping the services that write to them.
#
# Author: Vijay Kalvakolu
# ==============================================================================

# --- Configuration ---

# List of log files to truncate. Add full paths.
# Example: LOG_FILES=("/var/log/apache2/access.log" "/var/log/syslog")
LOG_FILES=("/var/log/disk_usage.log" "/var/log/network_monitor.log" "/var/log/backup.log" "/var/log/service_monitor.log")

# Log file for recording actions taken by this script.
# Ensure the user running this script has write permissions to this file/directory.
SCRIPT_LOG_FILE="/var/log/truncate_logs.log"

# --- Main Script Logic ---

# Function to log messages to a file and to the system logger
log_action() {
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %T")

    # Log to the dedicated script log file
    echo "[$timestamp] $message" >> "$SCRIPT_LOG_FILE"

    # Log to syslog with a 'user.info' priority for general info, 'user.err' for errors.
    if [[ "$message" == "ERROR:"* ]]; then
        logger -p user.err "LogTruncator: $message"
    else
        logger -p user.info "LogTruncator: $message"
    fi
}

log_action "INFO: Starting log truncation process."

# Iterate over the list of log files
for log_file in "${LOG_FILES[@]}"; do
    if [ -f "$log_file" ]; then
        log_action "INFO: Truncating log file: '$log_file'."

        # Get original permissions and ownership
        # Using stat -c "%a" for permissions (octal)
        # Using stat -c "%U" for owner name
        # Using stat -c "%G" for group name
        permissions=$(stat -c "%a" "$log_file")