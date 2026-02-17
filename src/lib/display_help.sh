# Function to display help
display_help() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --help, -h                      Show this help message and exit"
    echo "  --version, -v                   Show script version and exit"
    echo "  --input, -i <file|directory>    Specify the file or directory to process (if is directory, overrides actual_dir)"
    echo "  --log-level <level>             Set log level (DEBUG, INFO, WARNING, ERROR)"
    echo "  --estimate-size <file>          Estimate the size after H265 conversion for a file"
    echo "  --codec <file>                  Detect and print the codec for a file"
    echo "  --check-xattr <file>            Check if the xattr user.larger is present on a file"
    echo "  --cleanup-temp-files            Clean up temporary files created during processing"
    echo
    echo "Examples:"
    echo "  $0 --input /path/to/videos --log-level DEBUG"
    echo "  $0 --estimate-size /path/to/video.mp4"
    exit 0
}

export -f display_help
