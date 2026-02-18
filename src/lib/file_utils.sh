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

clear_xattr() {
    local file="$1"
    local attr="$2"

    if [[ ! -f "$file" ]]; then
        log "ERROR" "File does not exist: $file" "${LOG_FILE}"
        return 1
    fi

    if command -v xattr &>/dev/null; then
        xattr -d "$attr" "$file" 2>/dev/null
    else
        log "ERROR" "xattr is not available on this system" "${LOG_FILE}"
        return 1
    fi
}

clear_xattr_larger() {
    local file="$1"
    clear_xattr "$file" "user.larger"
}

clear_xattr_skip() {
    local file="$1"
    clear_xattr "$file" "user.skip"
}

check_xattr_skip() {
    local file="$1"
    local value
    value="$(check_xattr "$file" "user.skip")"
    [[ "$value" == "true" ]]
}

mark_xattr_skip() {
    local file="$1"
    mark_xattr "$file" "user.skip"
}


find_pending_files() {
    find "${ACTUAL_DIR}" -type f \
        \( -name "*.mkv" -o -name "*.avi" -o -name "*.mp4" -o -name "*.mov" -o -name "*.wmv" -o -name "*.flv" -o -name "*.m4v" -o -name "*.webm" -o -name "*.3gp" \) \
        -not -name "*.h265.mkv" -not -name "*.x265.mkv" | while read -r f; do
            codec=$(detect_codec "$f")
            if check_xattr_skip "$f"; then
                continue
            fi
            # Use the exit status of check_xattr_larger instead of capturing stdout
            if [[ "$codec" == "hevc" ]] && [[ "${f##*.}" != "${OUTPUT_EXTENSION}" ]]; then
                echo "$f"
            elif [[ "$codec" == "h264" ]] && [[ "${f##*.}" != "${OUTPUT_EXTENSION}" ]]; then
                echo "$f"
            else
                if ! check_xattr_larger "$f"; then
                    echo "$f"
                fi
            fi
        done
}

get_output_path() {
    local input_file="$1"
    local codec_suffix="$2"     # Ejemplo: x265, x264
    local base_name
    local dir_name

    base_name="$(basename "$input_file" | sed 's/\.[^.]*$//')"
    # Strip trailing codec token from filename (e.g., .h264, .x265, .hevc)
    base_name="$(echo "$base_name" | sed -E 's/\.(h26[45]|x26[45]|hevc)$//I')"
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

    if ! declare -f convert_to_h265_or_change_container &>/dev/null; then
        log "ERROR" "Function convert_to_h265_or_change_container is not defined" "${LOG_FILE}"
        return 1
    fi

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
export -f clear_xattr_larger
export -f clear_xattr_skip
export -f check_xattr_skip
export -f mark_xattr_skip
export -f process_file
export -f human_size
