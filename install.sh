#!/bin/bash
# ==============================================================================
# Automated One-Click Installer for ImunifyAV Free Quarantine System
# Must be executed as the root user on your server.
# ==============================================================================

# Ensure script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "[-] Error: Please run this installer script as root."
    exit 1
fi

echo "[*] Initializing ImunifyAV Free Quarantine Installer..."

# Define install targets
SCRIPT_PATH="/usr/local/bin/imunify-q"
CRON_PATH="/usr/local/bin/imunify_purge_cron.sh"

# ------------------------------------------------------------------------------
# 1. DEPLOY PRIMARY WORKER BINARY (imunify-q)
# ------------------------------------------------------------------------------
echo "[*] Deploying core quarantine utility to $SCRIPT_PATH..."

cat << 'EOF' > "$SCRIPT_PATH"
#!/bin/bash
# ==============================================================================
# Quiet, High-Performance Quarantine & Restore Manager for ImunifyAV Free
# Outputs clean updates instead of spamming 1000s of rows in your terminal.
# ==============================================================================

QUARANTINE_BASE="/root/imunify_quarantine"
LOG_FILE="$QUARANTINE_BASE/quarantine_history.log"
BATCH_REMOVE_LIST="/tmp/imunify_remove_batch.txt"
mkdir -p "$QUARANTINE_BASE"
true > "$BATCH_REMOVE_LIST"

if ! command -v jq &> /dev/null; then
    echo "[-] Error: 'jq' utility is missing."
    exit 1
fi

# INTERACTIVE RESTORE ENGINE
if [ "$1" = "--restore" ]; then
    TARGET_USER="$2"
    if [ -z "$TARGET_USER" ]; then
        echo "[-] Error: Please specify a username. Example: imunify-q --restore nekhreac"
        exit 1
    fi

    USER_QUARANTINE="$QUARANTINE_BASE/$TARGET_USER"
    if [ ! -d "$USER_QUARANTINE" ] || [ -z "$(ls -A "$USER_QUARANTINE" 2>/dev/null)" ]; then
        echo "[-] No quarantined files found for user: $TARGET_USER"
        exit 0
    fi

    echo "=================================================================="
    echo " Quarantined files for user: $TARGET_USER"
    echo "=================================================================="
    
    declare -A FILE_MAP
    INDEX=1
    
    while read -r LOG_LINE; do
        HASH_FILE=$(echo "$LOG_LINE" | grep -oP 'QUARANTINE: \K[^ ]+')
        ORIG_PATH=$(echo "$LOG_LINE" | grep -oP 'ORIGINAL: \K.*')
        
        if [ -f "$USER_QUARANTINE/$HASH_FILE" ]; then
            echo "[$INDEX] File: $HASH_FILE"
            echo "    Original Path: $ORIG_PATH"
            echo "------------------------------------------------------------------"
            FILE_MAP[$INDEX]="$HASH_FILE|$ORIG_PATH"
            ((INDEX++))
        fi
    done < <(grep "USER: $TARGET_USER" "$LOG_FILE" 2>/dev/null)

    if [ $INDEX -eq 1 ]; then
        echo "[-] Files exist but match history logs are missing."
        exit 1
    fi

    echo -n "Enter the number of the file you want to restore (or 'q' to quit): "
    read -r CHOICE

    if [ "$CHOICE" = "q" ] || [ -z "$CHOICE" ]; then
        echo "[*] Exiting without changes."
        exit 0
    fi

    SELECTED="${FILE_MAP[$CHOICE]}"
    if [ -z "$SELECTED" ]; then
        echo "[-] Invalid selection."
        exit 1
    fi

    HASH_FILE=$(echo "$SELECTED" | cut -d'|' -f1)
    ORIG_PATH=$(echo "$SELECTED" | cut -d'|' -f2)
    ORIG_DIR=$(dirname "$ORIG_PATH")

    echo "[*] Restoring $HASH_FILE to $ORIG_PATH..."
    mkdir -p "$ORIG_DIR"
    mv "$USER_QUARANTINE/$HASH_FILE" "$ORIG_PATH"
    chmod 644 "$ORIG_PATH"
    
    if id "$TARGET_USER" &>/dev/null; then
        chown "$TARGET_USER":"$TARGET_USER" "$ORIG_PATH"
    fi

    echo "[+] Successfully restored and fixed file permissions!"
    exit 0
fi

# BATCH QUARANTINE ENGINE
case "$1" in
    --all)
        echo "[*] Fetching global malicious list from ImunifyAV..."
        FILES=$(imunify-antivirus malware malicious list --limit 10000 --json 2>/dev/null | jq -c '.items[]' 2>/dev/null)
        ;;
    --user)
        if [ -z "$2" ]; then
            echo "[-] Error: Please specify a username. Example: imunify-q --user bdaio"
            exit 1
        fi
        echo "[*] Fetching malicious list for user: $2..."
        FILES=$(imunify-antivirus malware malicious list --user "$2" --limit 10000 --json 2>/dev/null | jq -c '.items[]' 2>/dev/null)
        ;;
    *)
        echo "Usage Layout:"
        echo "  imunify-q --all             Process all infected files across the entire server."
        echo "  imunify-q --user [username] Process infected files only for a specific account."
        echo "  imunify-q --restore [user]  Interactively pick and restore a file to its original place."
        exit 1
        ;;
esac

if [ -z "$FILES" ]; then
    echo "[+] Clean layout! No unresolved files found."
    rm -f "$BATCH_REMOVE_LIST"
    exit 0
fi

COUNTER=0
echo -n "[*] Isolating infected files in background... please wait."

while read -r ITEM; do
    if [ -z "$ITEM" ]; then continue; fi
    
    FILE_PATH=$(echo "$ITEM" | jq -r '.file')
    CURRENT_USER=$(echo "$ITEM" | jq -r '.username')
    
    if [ -f "$FILE_PATH" ] && [ -n "$CURRENT_USER" ]; then
        PATH_HASH=$(echo -n "$FILE_PATH" | md5sum | awk '{print $1}')
        FILE_EXT="${FILE_PATH##*.}"
        HASH_NAME="${PATH_HASH}.${FILE_EXT}"
        
        USER_DIR="$QUARANTINE_BASE/$CURRENT_USER"
        mkdir -p "$USER_DIR"
        QUARANTINE_TARGET="$USER_DIR/$HASH_NAME"
        
        echo "$(date '+%Y-%m-%d %H:%M:%S') | USER: $CURRENT_USER | ORIGINAL: $FILE_PATH | QUARANTINE: $HASH_NAME" >> "$LOG_FILE"
        
        mv "$FILE_PATH" "$QUARANTINE_TARGET"
        chmod 000 "$QUARANTINE_TARGET"
        
        echo "$FILE_PATH" >> "$BATCH_REMOVE_LIST"
        ((COUNTER++))
        
        if [ $((COUNTER % 10)) -eq 0 ]; then
            echo -n "."
        fi
    fi
done <<< "$FILES"

echo "" 

if [ $COUNTER -gt 0 ] && [ -s "$BATCH_REMOVE_LIST" ]; then
    echo "[*] Cleaning up Imunify UI dashboard entries..."
    xargs -a "$BATCH_REMOVE_LIST" -I {} imunify-antivirus malware malicious remove-from-list {} >/dev/null 2>&1
fi

rm -f "$BATCH_REMOVE_LIST"
echo "[+] Done! Total files isolated and logged: $COUNTER"
EOF

chmod +x "$SCRIPT_PATH"
echo "[+] core script configured cleanly."

# ------------------------------------------------------------------------------
# 2. DEPLOY ROTATION CLEANUP SCRIPT (imunify_purge_cron.sh)
# ------------------------------------------------------------------------------
echo "[*] Deploying automated cleanup engine to $CRON_PATH..."

cat << 'EOF' > "$CRON_PATH"
#!/bin/bash
# ==============================================================================
# Nightly Retention Manager Module for ImunifyAV Free Quarantine System
# Automated cleanup running via crontab to maintain stable filesystem overhead.
# ==============================================================================

QUARANTINE_BASE="/root/imunify_quarantine"
LOG_FILE="$QUARANTINE_BASE/quarantine_history.log"

if [ -n "$QUARANTINE_BASE" ] && [ -d "$QUARANTINE_BASE" ]; then
    find "$QUARANTINE_BASE" -type f -mtime +14 -not -name "quarantine_history.log" -exec rm -f {} \;
    find "$QUARANTINE_BASE" -mindepth 1 -type d -empty -delete
    if [ -f "$LOG_FILE" ]; then
        tail -n 5000 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
else
    echo "CRITICAL ERROR: Quarantine directory path is invalid or missing. Aborting to protect server."
    exit 1
fi
EOF

chmod +x "$CRON_PATH"
echo "[+] Retention scheduler configured cleanly."

# ------------------------------------------------------------------------------
# 3. CONFIGURE ROOT CRONTAB
# ------------------------------------------------------------------------------
echo "[*] Automating cleanup script into root system crontab..."

# Read existing cron, filter out existing references to this script, add new line
(crontab -l 2>/dev/null | grep -v "$CRON_PATH"; echo "0 0 * * * $CRON_PATH >/dev/null 2>&1") | crontab -

echo "[+] Crontab update complete (scheduled for midnight execution nightly)."
echo "======================================================================"
echo "[+] SUCCESS! Deployment complete."
echo "    - Execute quarantine via:  imunify-q --user [username]"
echo "    - Restore false positives: imunify-q --restore [username]"
echo "======================================================================"
