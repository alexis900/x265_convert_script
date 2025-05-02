#!/bin/bash

# Function to create a backup of the original file
backup_file() {
    local file="$1"
    mkdir -p "${BACKUP_DIR}"
    cp "$file" "${BACKUP_DIR}"
    log "INFO" "Backup created for: $file" "${LOG_FILE}"
}

# Function to delete the backup of the original file
delete_backup() {
    local file="$1"
    local backup_file="${BACKUP_DIR}/$(basename "$file")"
    if [[ -f "$backup_file" ]]; then
        rm "$backup_file"
        log "INFO" "Backup deleted for: $file" "${LOG_FILE}"
    fi
}

# Function to clean up temporary files
cleanup_temp_files() {
    if ls /tmp/tmp_h265_part_*.mkv 1> /dev/null 2>&1; then
        rm -f /tmp/tmp_h265_part_*.mkv
        log "INFO" "Temporary files deleted" "${LOG_FILE}"
    fi
}