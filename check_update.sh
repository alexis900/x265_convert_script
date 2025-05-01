#!/bin/bash
# This script checks for updates to the x265 convert script and notifies the user if a new version is available.

# Check if the version file exists
if [[ ! -f "${SHARE_PATH}/version" ]]; then
    echo "Error: Version file does not exist. Exiting..."
    exit 1
fi
# Check if the version file is readable
if [[ ! -r "${SHARE_PATH}/version" ]]; then
    echo "Error: Version file is not readable. Exiting..."
    exit 1
fi

check_update_version(){
    source "${SHARE_PATH}/version"
    local current_version="${VERSION}-${CHANNEL}"
    local response=$(curl -s "${CHECK_LATESTS_VERSION}")
    local latest_version=$(echo "$response" | grep -oP 'VERSION=\K[0-9]+(\.[0-9]+){3}')
    local latest_channel=$(echo "$response" | grep -oP 'CHANNEL=\K[a-zA-Z]+')
    IFS='.' read -r -a current_parts <<< "$VERSION"
    IFS='.' read -r -a latest_parts <<< "$latest_version"

    for i in {0..3}; do
        if (( ${latest_parts[i]} > ${current_parts[i]} )); then
            echo "A new version is available: $latest_version-$latest_channel (current: $current_version)"
            return
        elif (( ${latest_parts[i]} < ${current_parts[i]} )); then
            break
        fi
    done

    echo "You are using the latest version: $current_version"
}

export -f check_update_version