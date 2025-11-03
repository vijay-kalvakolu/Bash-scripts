#!/bin/bash

# ==============================================================================
# network_monitor.sh
#
# A script to monitor network connectivity to specified targets (IPs or hostnames).
# It uses `ping` to check reachability and logs status changes to avoid
# log spam. It will log when a target goes down and when it comes back up.
#
# Author: Vijay Kalvakolu
# ==============================================================================

# --- Configuration ---

# List of network targets to monitor.
# Include a mix of:
#   - Your local gateway (e.g., "192.168.1.1") to check local network health.
#   - A reliable external IP (e.g., "8.8.8.8") to check internet connectivity.
#   - A reliable DNS name (e.g., "google.com") to check DNS resolution.
TARGETS=("192.168.1.1" "8.8.8.8" "google.com")

# Log file for recording status changes.
# Ensure the user running this script has write permissions to this file/directory.
LOG_FILE="/var/log/network_monitor.log"

# Directory to store the status of each host (to detect changes).
# This helps prevent spamming the log file on every check.
STATE_DIR="/tmp/network_monitor_state"

# Ping parameters
# -c 1: Send only 1 packet.
# -W 2: Wait a maximum of 2 seconds for a reply.
PING_COUNT=1
PING_TIMEOUT=2

# --- Main Script Logic ---

# Ensure the state directory exists
mkdir -p "$STATE_DIR"

# Function to log messages to a file and to the system logger
log_action() {
    local message="$1"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %T")

    # Log to the dedicated log file
    echo "[$timestamp] $message" >> "$LOG_FILE"

    # Log to syslog with a 'user.warning' priority
    logger -p user.warn "NetworkMonitor: $message"
}

# Iterate over all configured targets
for target in "${TARGETS[@]}"; do
    # Sanitize the target name to create a valid filename for the state file
    state_file="${STATE_DIR}/${target//[^a-zA-Z0-9._-]/_}.status"

    # Use `ping` with a timeout. The --quiet flag is not used so we can capture output if needed,
    # but we redirect stdout and stderr to /dev/null to keep the script's output clean.
    if ping -c "$PING_COUNT" -W "$PING_TIMEOUT" "$target" &> /dev/null; then
        # --- Target is UP ---
        if [ -f "$state_file" ]; then
            # The state file exists, which means the target was previously DOWN.
            log_action "RECOVERY: Network target '$target' is back online."
            # Remove the state file to mark it as UP.
            rm "$state_file"
        fi
        # If no state file exists, the target was already up, so we do nothing.
    else
        # --- Target is DOWN ---
        if [ ! -f "$state_file" ]; then
            # The state file does not exist, so this is the first time we've detected it's down.
            log_action "ALERT: Network target '$target' is unreachable."
            # Create the state file to mark it as DOWN.
            touch "$state_file"
        fi
        # If the state file already exists, the target is still down, so we do nothing.
    fi
done

