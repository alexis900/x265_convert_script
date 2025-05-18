#!/usr/bin/env bash
# Detect if running from a deb package install or from source directory
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
if [[ -d "/usr/local/share/x265_convert_script" && $SCRIPT_DIR == "/usr/local/bin" ]]; then
    SHARE_PATH="/usr/local/share/x265_convert_script"
else
    SHARE_PATH="$SCRIPT_DIR"
fi

SRC_PATH="$SHARE_PATH/src"
# Load environment variables and utility functions
if [[ -f "$SHARE_PATH/config/preferences.conf" ]]; then
    source "$SHARE_PATH/config/preferences.conf"
else
    echo "Error: preferences.conf not found in the current directory. Exiting..."
    exit 1
fi

# Verify if the required files exist
declare -A required_files=(
    ["logging.sh"]="$SRC_PATH"
    ["file_utils.sh"]="$SRC_PATH"
    ["backup.sh"]="$SRC_PATH"
    ["check_update.sh"]="$SRC_PATH"
    ["media_utils.sh"]="$SRC_PATH"
)

for file in "${!required_files[@]}"; do
    full_path="${required_files[$file]}/$file"
    if [[ ! -f "$full_path" ]]; then
        echo "Error: Required file $file does not exist in ${required_files[$file]}. Exiting..."
        exit 1
    fi

    if [[ "$file" == *.sh ]]; then
        # shellcheck disable=SC1090
        source "$full_path"
    fi
done
