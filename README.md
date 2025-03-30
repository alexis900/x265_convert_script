# x265 Convert Script

This script converts video files to H265 (HEVC) format or changes their container if they are already in H265 but not in MKV format. If the estimated size of the file converted to H265 is larger than the original and the original codec is not H264, the file will be converted to H264 with the extension `.x264.mkv`.

## Requirements

- `ffmpeg`
- `ffprobe`
- `xattr` (optional, to mark files with extended attributes)

## Usage

1. Run the conversion script with the default directory:
    ```bash
    ./convert_x265.sh
    ```

2. Optionally, specify a custom directory to process using the `--dir` argument:
    ```bash
    ./convert_x265.sh --dir /path/to/custom/directory
    ```

3. Specify a single file to process using the `--file` argument:
    ```bash
    ./convert_x265.sh --file /path/to/file
    ```

4. Display the version of the script using the `--version` argument:
    ```bash
    ./convert_x265.sh --version
    ```

5. Display help information using the `--help` argument:
    ```bash
    ./convert_x265.sh --help
    ```

### Arguments

- `--help` or `-h`: Displays help information about the script and its usage.
- `--version` or `-v`: Displays the version information of the script.
- `--dir PATH` or `-d PATH`: Specifies a custom directory to process. This overrides the `actual_dir` variable defined in the `env.sh` file.
- `--file FILE` or `-f FILE`: Specifies a single file to process instead of processing an entire directory.

If no directory is specified using `--dir` or no file is specified using `--file`, the script will use the default directory specified in `env.sh`.

## Environment Variables

The `env.sh` file contains the following variables:

- `actual_dir`: The directory where the video files are located.
- `log_file`: The path to the main log file.
- `ffmpeg_log_file`: The path to the log file for `ffmpeg` output.
- `remaining_log`: The path to the log file for remaining files.

Example `env.sh` file:
```bash
# env.sh
actual_dir="/path/to/video/directory"
log_file="/path/to/log/file/convert.log"
ffmpeg_log_file="/path/to/log/file/ffmpeg.log"
remaining_log="/path/to/log/file/remaining.log"
```

## Main Functions

- `log()`: Logs events with a timestamp to a log file and the screen.
- `backup_file()`: Creates a backup of the original file.
- `delete_backup()`: Deletes the backup of the original file.
- `has_valid_subtitles()`: Checks if the file has valid subtitles.
- `estimate_h265_size()`: Estimates the size of the file after conversion to H265.
- `verify_quality()`: Verifies the quality of the converted file.
- `convert_to_h265_or_change_container()`: Converts the file to H265 or changes the container. If the estimated size of the file converted to H265 is larger than the original and the original codec is not H264, the file will be converted to H264 with the extension `.x264.mkv`. If the conversion fails, the original file is restored from the backup.
- `cleanup_temp_files()`: Cleans up temporary files created during the conversion process.
- `handle_signal()`: Handles signals (e.g., SIGINT, SIGTERM) to clean up and exit gracefully.
- `process_file()`: Processes a single file for conversion or container change.

## Additional Scripts

- `check_x265.sh`: Checks for pending files that need to be processed. It verifies the existence of required files (`env.sh`, `logging.sh`, `file_utils.sh`) before proceeding. If any of these files are missing, the script exits with an error. Additionally, it ensures the directory specified in `actual_dir` exists before searching for pending files. It logs the files that have not been processed yet and skips those that have the 'larger' attribute set.
- `logging.sh`: Contains the `log` function used for logging events.
- `file_utils.sh`: Contains utility functions for file operations, including finding pending files and checking extended attributes.

## Package Generation Scripts

- `create_deb_package.sh`: Script to automate the generation of a `.deb` package.
- `create_rpm_package.sh`: Script to automate the generation of a `.rpm` package.

## Notes

- The script searches for video files in the directory specified in `actual_dir` and processes them one by one.
- If no files are found to convert or change the container, the script exits.
- The script waits 10 seconds before searching for new files to process.

## License

This project is licensed under the terms of the MIT license.