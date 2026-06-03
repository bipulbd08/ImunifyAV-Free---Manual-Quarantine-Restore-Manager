#!/bin/bash
# ==============================================================================
# Nightly Retention Manager Module for ImunifyAV Free Quarantine System
# Automated cleanup running via crontab to maintain stable filesystem overhead.
# ==============================================================================

QUARANTINE_BASE="/root/imunify_quarantine"
LOG_FILE="$QUARANTINE_BASE/quarantine_history.log"

# STRICT SAFETY CHECK: Ensure the variable is NOT empty and the directory actually exists
if [ -n "$QUARANTINE_BASE" ] && [ -d "$QUARANTINE_BASE" ]; then
    
    # 1. Permanently delete isolated files inside the quarantine directory older than 14 days
    find "$QUARANTINE_BASE" -type f -mtime +14 -not -name "quarantine_history.log" -exec rm -f {} \;
    
    # 2. Delete empty user subdirectories within quarantine so it stays tidy
    find "$QUARANTINE_BASE" -mindepth 1 -type d -empty -delete
    
    # 3. Keep log history tidy by keeping only the latest 5000 entries
    if [ -f "$LOG_FILE" ]; then
        tail -n 5000 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
else
    echo "CRITICAL ERROR: Quarantine directory path is invalid or missing. Aborting to protect server."
    exit 1
fi
