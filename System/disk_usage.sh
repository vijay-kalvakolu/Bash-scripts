#!/bin/bash

# ==============================================================================
# disk_usage.sh
#
# A script to monitor disk usage, identify large files or directories,
# and log alerts if usage exceeds a specified threshold.
#
# Author: Vijay Kalvakolu
# ==============================================================================

# --- Configuration ---

# Disk usage threshold in percentage. If any mounted filesystem exceeds this, an alert is logged.
USAGE_THRESHOLD=90

# Number of top largest directories/files to report.
TOP_COUNT=10

# Log file for recording alerts and findings.
LOG_FILE="/var/log/disk_usage.log"

# Directories to scan for large files/directories.
# Add or remove paths as needed. Be cautious with scanning root (/) on very large systems.
SCAN_PATHS=("/" "/var" "/home")

# --- Main Script Logic ---

# Function to log messages to a file and to the system logger
log_action() {
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %T")

    # Log to the dedicated log file
    echo "[$timestamp] $message" >> "$LOG_FILE"

    # Log to syslog with a 'user.warning' priority
    logger -p user.warn "DiskMonitor: $message"
}

log_action "INFO: Starting disk usage check."

# 1. Check overall disk usage for all mounted filesystems
df -hP | awk 'NR>1 {print $1, $5, $6}' | while read -r filesystem usage mountpoint; do
    # Remove '%' sign from usage and convert to integer
    current_usage=${usage%\%}
    if (( current_usage >= USAGE_THRESHOLD )); then
        log_action "ALERT: Disk usage on '$mountpoint' ($filesystem) is at ${current_usage}% (threshold: ${USAGE_THRESHOLD}%)."
    fi
done

# 2. Identify large files and directories in specified paths
log_action "INFO: Identifying large files and directories in specified paths."

for path in "${SCAN_PATHS[@]}"; do
    if [ -d "$path" ]; then
        log_action "INFO: Scanning '$path' for large directories..."
        # Find top N largest directories
        echo "