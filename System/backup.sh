#!/bin/bash

# ==============================================================================
# backup.sh
#
# A script to perform backups of specified local directories/files and
# then transfer these backups to a remote server using rsync over SSH.
#
# Author: Vijay Kalvakolu
# ==============================================================================

# --- Configuration ---

# Directories/files to back up. Add full paths.
# Example: BACKUP_SOURCES=("/home/user/documents" "/var/www/html")
BACKUP_SOURCES=("/etc" "/home/vijay/test_data")

# Destination directory on the local machine where backups will be temporarily stored.
LOCAL_BACKUP_DIR="/tmp/backups"

# Remote server details for backup transfer.
REMOTE_USER="vijay"         # SSH username on the remote server
REMOTE_HOST="192.168.1.100" # Remote server IP address or hostname
REMOTE_DEST_DIR="/mnt/backup_storage/my_server_backups" # Destination directory on the remote server

# Log file for recording backup actions and errors.
LOG_FILE="/var/log/backup.log"

# Retention policy: How many days to keep local and remote backups.
# Set to 0 to disable local cleanup, or a positive integer for days.
LOCAL_RETENTION_DAYS=7
REMOTE_RETENTION_DAYS=30

# --- Main Script Logic ---

# Function to log messages to a file and to the system logger
log_action() {
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %T")

    # Log to the dedicated log file
    echo "[$timestamp] $message" >> "$LOG_FILE"

    # Log to syslog with a 'user.info' priority for general info, 'user.err' for errors.
    if [[ "$message" == "ERROR:"* ]]; then
        logger -p user.err "BackupScript: $message"
    else
        logger -p user.info "BackupScript: $message"
    fi
}

log_action "INFO: Starting backup process."

# Ensure local backup directory exists
mkdir -p "$LOCAL_BACKUP_DIR" || { log_action "ERROR: Failed to