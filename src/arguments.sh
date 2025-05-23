#!/bin/bash

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            display_help
            ;;
        --version|-v)
            readonly check_update="$SRC_PATH/check_update.sh"
            if [[ -f "$check_update" ]]; then
                source "$check_update"
                check_update_version
                exit 0
            else
                echo "Error: $check_update not found. Exiting..."
                exit 1
            fi
            ;;
        --dir|-d)
            if [[ -n "$2" ]]; then
                ACTUAL_DIR="$2"
                shift
            else
                echo "Error: --dir requires a directory path as an argument."
                exit 1
            fi
            ;;
        --file|-f)
            if [[ -n "$2" ]]; then
                if [[ -f "$2" ]]; then
                    process_file "$2"
                else
                    echo "Error: File $2 does not exist."
                    exit 1
                fi
            else
                echo "Error: --file requires a file path as an argument."
                exit 1
            fi
            ;;
        --codec|-c)
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
        *)
            echo "Unknown option: $1"
            display_help
            ;;
    esac
    shift
done