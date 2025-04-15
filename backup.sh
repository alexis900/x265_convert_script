#!/bin/bash

# Function to create a backup of the original file
backup_file() {
    local file="$1"
    mkdir -p "$BACKUP_DIR"
    cp "$file" "$BACKUP_DIR"
    log "INFO" "Backup created for: $file" "$log_file"
}

# Function to delete the backup of the original file
delete_backup() {
    local file="$1"
    local backup_file="$BACKUP_DIR/$(basename "$file")"
    if [[ -f "$backup_file" ]]; then
        rm "$backup_file"
        log "INFO" "Backup deleted for: $file" "$log_file"
    fi
}

# Function to clean up temporary files
cleanup_temp_files() {
    rm -f /tmp/tmp_h265_part_*.mkv
    log "INFO" "Temporary files deleted" "$log_file"
}