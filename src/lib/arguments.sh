#!/bin/bash

check_input() {
    local input="$1"
    if [[ -d "$input" ]]; then
        ACTUAL_DIR="$input"
    elif [[ -f "$input" ]]; then
        process_file "$input"
    else
        log "ERROR" "Input path '$input' must be a file or directory" "${LOG_FILE}"
        return 1
    fi
}

PARSED=$(getopt -o hi:c:v --long help,input:,version,codec:,log-level:,estimate-size:,check-xattr,cleanup-temp-files,list-profiles,profile: -n 'x265_convert' -- "$@")

eval set -- "$PARSED"

# Parse arguments
while true; do
    case "$1" in
        -h|--help)
            display_help
            exit 0
            ;;
        -v|--version)
                check_update_version
                exit 0
            ;;
        -i|--input)
                check_input "$2"
                shift
            ;;
        -c|--codec)
            if [[ -n "$2" ]]; then
                detect_codec "$2"
                exit 0
            else
                echo "Error: --codec requires a codec as an argument."
                exit 1
            fi
            ;;
        --log-level)
            if [[ -n "$2" ]]; then
                LOG_LEVEL="$2"
                shift
            else
                echo "Error: --log-level requires a log level as an argument."
                exit 1
            fi
            ;;
        --estimate-size)
            if [[ -n "$2" ]]; then
                estimate_video_size "$2"
                exit 0
            else
                echo "Error: --estimate-size requires a file path as an argument."
                exit 1
            fi
            ;;
        --check-xattr)
            if [[ -n "$2" ]]; then
                check_xattr_larger "$2"
                exit 0
            else
                echo "Error: --check-xattr requires a file path as an argument."
                exit 1
            fi
            ;;
        # This option cleans up temporary files created during processing and exits immediately.
        --cleanup-temp-files)
            cleanup_temp_files
            exit 0
            ;;
        --list-profiles)
            if [[ -d "$SRC_PATH/profiles" ]]; then
                echo "Available profiles:"
                ls "$SRC_PATH/profiles"
            else
                echo "Error: Profiles directory not found."
                exit 1
            fi
            exit 0
            ;;
        --profile)
            if [[ -n "$2" ]]; then
                load_profile "$2"
                shift
            else
                echo "Error: --profile requires a profile file as an argument."
                exit 1
            fi
            ;;
        --) shift; break ;;
        *)
            echo "Error: Unknown option: $1" >&2
            display_help
            exit 1
        ;;
    esac
    shift
done