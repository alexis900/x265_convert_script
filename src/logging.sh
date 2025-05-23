#!/bin/bash

# Define log levels in order of priority
declare -A LOG_LEVELS=(["DEBUG"]=0 ["INFO"]=1 ["WARNING"]=2 ["ERROR"]=3)

# Default to DEBUG if LOG_LEVEL is not set
LOG_LEVEL="${LOG_LEVEL:-DEBUG}"

# Function to set log level
set_log_level() {
    case "$1" in
        DEBUG|INFO|WARNING|ERROR)
            LOG_LEVEL="$1"
            ;;
        *)
            echo "Invalid log level: $1. Valid levels are DEBUG, INFO, WARNING, ERROR."
            exit 1
            ;;
    esac
}

log() {
    local level="$1"
    local message="$2"
    local logfile="$3"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    if [[ ! -d "${HOME}/.cache/x265_convert/logs/" ]]; then
        mkdir -p "${HOME}/.cache/x265_convert/logs/"
    fi

    # Use the LOG_LEVEL environment variable
    if [[ ${LOG_LEVELS[$level]} -ge ${LOG_LEVELS[$LOG_LEVEL]} ]]; then
        echo "[$timestamp] [$level] $message" | tee -a "$logfile"
    fi
}
