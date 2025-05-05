#!/bin/bash

# This script contains utility functions for the x265 convert script.


find_pending_files() {
    find "${ACTUAL_DIR}" -type f \
        \( -name "*.mkv" -o -name "*.avi" -o -name "*.mp4" -o -name "*.mov" -o -name "*.wmv" -o -name "*.flv" -o -name "*.m4v" -o -name "*.webm" -o -name "*.3gp" \) \
        -not -name "*.h265.mkv" -not -name "*.x265.mkv" | while read -r f; do
            codec=$(detect_codec "$f")
            xattr_output=$(check_xattr_larger "$f")
            if [[ "$codec" == "hevc" ]] && [[ "${f##*.}" != "mkv" ]]; then
                echo "$f"
            elif [[ "$codec" == "h264" ]] && [[ "${f##*.}" != "mkv" ]]; then
                echo "$f"
            elif [[ "$codec" != "hevc" && "$xattr_output" != "true" ]]; then
                echo "$f"
            fi
        done
}

# Function to check if the file has the 'larger' attribute
check_xattr_larger() {
    local file="$1"
    if command -v xattr &>/dev/null; then
        xattr -p user.larger "$file" 2>/dev/null
    else
        log "ERROR" "xattr is not available on this system" "${LOG_FILE}"
        return 1
    fi
}

# Function to mark the file with the 'larger' attribute
mark_xattr_larger() {
    local file="$1"
    if command -v xattr &>/dev/null; then
        xattr -w user.larger true "$file"
    else
        log "ERROR" "xattr is not available on this system" "${LOG_FILE}"
    fi
}

process_file() {
    local file="$1"
    local codec=$(detect_codec "$file")
    if [[ -z "$codec" ]]; then
        log "ERROR" "Error: Could not detect codec of file $file" "${LOG_FILE}"
        return 1
    fi
    local new_path="$(dirname "$file")/$(basename "$file" | cut -d. -f1).x265.mkv"
    log "DEBUG" "Detected codec for $file: $codec" "${LOG_FILE}"
    convert_to_h265_or_change_container "$file" "$new_path" "$codec"
}

human_size() {
    numfmt --to=iec "$1"
}

export -f find_pending_files
export -f check_xattr_larger
export -f mark_xattr_larger
export -f process_file
export -f human_size