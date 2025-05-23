# Function to display help
display_help() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --help, -h                Show this help message and exit"
    echo "  --version, -v             Show script version and exit"
    echo "  --dir, -d <directory>     Specify the directory to process (overrides actual_dir)"
    echo "  --file, -f <file>         Specify a single file to process"
    echo "  --log-level <level>       Set log level (DEBUG, INFO, WARNING, ERROR)"
    echo "  --estimate-size <file>    Estimate the size after H265 conversion for a file"
    echo "  --check-xattr <file>      Check if the xattr user.larger is present on a file"
    echo "  --cleanup-temp-files      Clean up temporary files created during processing"
    echo
    echo "Examples:"
    echo "  $0 --dir /path/to/videos --log-level DEBUG"
    echo "  $0 --file /path/to/video.mp4"
    echo "  $0 --estimate-size /path/to/video.mp4"
    exit 0
}

export -f display_help