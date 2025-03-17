#!/bin/bash

log() {
    local level="$1"
    local message="$2"
    local logfile="$3"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" | tee -a "$logfile"
}
