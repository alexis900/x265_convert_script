#!/bin/bash
# This script checks for updates to the x265 convert script and notifies the user if a new version is available.

# Check if the version file exists

VERSION_FILE="${SHARE_PATH}/src/version"
if [[ ! -f $VERSION_FILE ]]; then
    echo $VERSION_FILE
    echo "Error: Version file does not exist. Exiting..."
    exit 1
fi
# Check if the version file is readable
if [[ ! -r $VERSION_FILE ]]; then
    echo "Error: Version file is not readable. Exiting..."
    exit 1
fi

check_update_version(){
    source $VERSION_FILE
    local current_version="${VERSION}-${CHANNEL}"
    local response
    response=$(curl -fsSL --max-time 5 "${CHECK_LATESTS_VERSION}") || {
        echo "Warning: Unable to check for updates (network error)."
        return
    }
    local latest_version
    local latest_channel
    latest_version=$(echo "$response" | grep -Eo 'VERSION=[0-9]+(\.[0-9]+){3}' | head -n1 | cut -d= -f2)
    latest_channel=$(echo "$response" | grep -Eo 'CHANNEL=[A-Za-z]+' | head -n1 | cut -d= -f2)
    if [[ -z "$latest_version" ]]; then
        echo "Warning: Unable to parse latest version."
        return
    fi
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
