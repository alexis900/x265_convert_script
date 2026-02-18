#!/bin/bash

# Function to generate a deterministic backup path for a file
backup_path_for_file() {
    local file="$1"
    local safe_path="${file#/}"          # drop leading slash for portability
    safe_path="${safe_path//\//__}"      # replace slashes to avoid directories
    echo "${BACKUP_DIR}/${safe_path}.bak"
}

# Function to create a backup of the original file
backup_file() {
    local file="$1"
    local backup_path
    backup_path="$(backup_path_for_file "$file")"
    mkdir -p "${BACKUP_DIR}"
    cp "$file" "$backup_path"
    log "INFO" "Backup created for: $file" "${LOG_FILE}"
}

# Function to delete the backup of the original file
delete_backup() {
    local file="$1"
    local backup_file
    backup_file="$(backup_path_for_file "$file")"
    if [[ -f "$backup_file" ]]; then
        rm "$backup_file"
        log "INFO" "Backup deleted for: $file" "${LOG_FILE}"
    fi
}

export -f backup_path_for_file

# Function to clean up temporary files
cleanup_temp_files() {
    if ls /tmp/tmp_h265_part_*.mkv 1> /dev/null 2>&1; then
        log "INFO" "Cleaning up temporary files..." "${LOG_FILE}"
        rm -f /tmp/tmp_h265_part_*.mkv
    else
        log "INFO" "No temporary files to clean up." "${LOG_FILE}"
    fi
}
