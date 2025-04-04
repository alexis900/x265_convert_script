#!/bin/bash

# This script contains utility functions for the x265 convert script.

find_pending_files() {
    find "$actual_dir" -type f \
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

# Function to detect the video codec of the file
detect_codec() {
    ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$1"
}

# Function to check if the file has the 'larger' attribute
check_xattr_larger() {
    local file="$1"
    if command -v xattr &>/dev/null; then
        xattr -p user.larger "$file" 2>/dev/null
    else
        log "ERROR" "xattr is not available on this system" "$log_file"
        return 1
    fi
}

# Function to mark the file with the 'larger' attribute
mark_xattr_larger() {
    local file="$1"
    if command -v xattr &>/dev/null; then
        xattr -w user.larger true "$file"
    else
        log "ERROR" "xattr is not available on this system" "$log_file"
    fi
}

export -f find_pending_files
export -f detect_codec
export -f check_xattr_larger
export -f mark_xattr_larger