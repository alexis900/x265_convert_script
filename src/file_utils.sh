#!/bin/bash

# This script contains utility functions for the x265 convert script.

check_xattr() {
    local file="$1"
    local attr="$2"
    if command -v xattr &>/dev/null; then
        xattr -p "$attr" "$file" 2>/dev/null
    else
        log "ERROR" "xattr is not available on this system" "${LOG_FILE}"
        return 2
    fi
}

# Function to check if the file has the 'larger' attribute
check_xattr_larger() {
    local file="$1"
    local value
    value="$(check_xattr "$file" "user.larger")"
    [[ "$value" == "true" ]]
}

mark_xattr() {
    local file="$1"
    local attr="$2"

    if [[ ! -f "$file" ]]; then
        log "ERROR" "File does not exist: $file" "${LOG_FILE}"
        return 1
    fi

    if command -v xattr &>/dev/null; then
        xattr -w "$attr" true "$file"
    else
        log "ERROR" "xattr is not available on this system" "${LOG_FILE}"
        return 1
    fi
}

# Function to mark the file with the 'larger' attribute
mark_xattr_larger() {
    local file="$1"
    mark_xattr "$file" "user.larger"
}


find_pending_files() {
    find "${ACTUAL_DIR}" -type f \
        \( -name "*.mkv" -o -name "*.avi" -o -name "*.mp4" -o -name "*.mov" -o -name "*.wmv" -o -name "*.flv" -o -name "*.m4v" -o -name "*.webm" -o -name "*.3gp" \) \
        -not -name "*.h265.mkv" -not -name "*.x265.mkv" | while read -r f; do
            codec=$(detect_codec "$f")
            xattr_output=$(check_xattr_larger "$f")
            if [[ "$codec" == "hevc" ]] && [[ "${f##*.}" != "${OUTPUT_EXTENSION}" ]]; then
                echo "$f"
            elif [[ "$codec" == "h264" ]] && [[ "${f##*.}" != "${OUTPUT_EXTENSION}" ]]; then
                echo "$f"
            elif [[ "$codec" != "hevc" && "$xattr_output" != "true" ]]; then
                echo "$f"
            fi
        done
}

get_output_path() {
    local input_file="$1"
    local codec_suffix="$2"     # Ejemplo: x265, x264
    local base_name
    local dir_name

    base_name="$(basename "$input_file" | sed 's/\.[^.]*$//')"
    dir_name="$(dirname "$input_file")"

    # Validar que OUTPUT_EXTENSION esté definida
    if [[ -z "$OUTPUT_EXTENSION" ]]; then
        echo "Error: OUTPUT_EXTENSION no está definida." >&2
        return 1
    fi

    local ext="${OUTPUT_EXTENSION#.}"  # Eliminar punto inicial si lo hay

    echo "${dir_name}/${base_name}.${codec_suffix}.${ext}"
}


process_file() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        log "ERROR" "File does not exist: $file" "${LOG_FILE}"
        return 1
    fi

    local codec
    codec=$(detect_codec "$file")

    if [[ -z "$codec" ]]; then
        log "ERROR" "Could not detect codec of file $file" "${LOG_FILE}"
        return 1
    fi

    local new_path
    new_path=$(get_output_path "$file" "x265")

    log "DEBUG" "Detected codec for $file: $codec" "${LOG_FILE}"
    log "DEBUG" "Output path for $file: $new_path" "${LOG_FILE}"

    convert_to_h265_or_change_container "$file" "$new_path" "$codec"
}

human_size() {
    local input="$1"
    if [[ ! "$input" =~ ^[0-9]+$ ]]; then
        echo "Error: input must be a positive integer" >&2
        return 1
    fi
    numfmt --to=iec "$input"
}

export -f find_pending_files
export -f check_xattr_larger
export -f mark_xattr_larger
export -f process_file
export -f human_size