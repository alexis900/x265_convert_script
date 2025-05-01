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

3. Display the version of the script using the `--version` argument:
    ```bash
    ./convert_x265.sh --version
    ```

4. Display help information using the `--help` argument:
    ```bash
    ./convert_x265.sh --help
    ```

### Arguments

- `--help` or `-h`: Displays help information about the script and its usage.
- `--version` or `-v`: Displays the version information of the script.
- `--dir PATH` or `-d PATH`: Specifies a custom directory to process. This overrides the `actual_dir` variable defined in the `preferences.conf` file.
- `--file PATH` or `-f PATH`: Specifies a single file to process.
- `--codec CODEC` or `-c CODEC`: Detects the codec of the specified file.
- `--log-level LEVEL`: Sets the log level (DEBUG, INFO, WARNING, ERROR).

If no directory is specified using `--dir`, the script will use the default directory specified in `preferences.conf`.

## Environment Variables

The `preferences.conf` file contains the following variables:

- `ACTUAL_DIR`: The directory where the video files are located.
- `LOG_FILE`: The path to the main log file.
- `FFMPG_LOG_FILE`: The path to the log file for `ffmpeg` output.
- `REMAINING_LOG`: The path to the log file for remaining files.
- `CHECK_LATESTS_VERSION`: URL to check for script updates.
- `SHARE_PATH`: Path to shared resources for the script.
- `FFMPEG_PRESET`: Preset for `ffmpeg` encoding.
- `FFMPEG_CRF`: Constant Rate Factor for video quality.
- `FFMPEG_VIDEO_CODEC`: Video codec to use (default: `libx265`).
- `FFMPEG_AUDIO_CODEC`: Audio codec to use (default: `copy`).
- `FFMPEG_SUBTITLE_CODEC`: Subtitle codec to use (default: `srt`).
- `FFMPEG_LOG_LEVEL`: Log level for `ffmpeg` (default: `error`).
- `BACKUP_DIR`: Directory for storing backups of original files.
- `LOG_LEVEL`: Default log level for the script (default: `DEBUG`).

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

## Recent Changes

- **H265 Size Estimation**: The script now estimates the file size after conversion to H265 to decide whether to switch the codec to H264.
- **Quality Verification**: Compares the duration of the original and converted files to ensure quality.
- **Subtitle Handling**: Detects if the file has valid subtitles and includes them in the conversion if necessary.
- **Backup and Restore**: Creates a backup of the original file before conversion and restores it in case of failures.
- **Signal Handling**: Cleans up temporary files and exits safely upon receiving signals like SIGINT or SIGTERM.
- **Log Level Parameter**: Allows configuring the log level (DEBUG, INFO, WARNING, ERROR) using the `--log-level` argument.

### New Functions

- `estimate_h265_size()`: Estimates the file size after conversion to H265.
- `verify_quality()`: Verifies the quality of the converted file by comparing its duration with the original.
- `has_valid_subtitles()`: Checks if the file has valid subtitles (srt, subrip, ass, ssa).
- `backup_file()` and `delete_backup()`: Manage the creation and deletion of backups for original files.
- `handle_signal()`: Handles signals to clean up temporary files and exit safely.

## Man Page

A man page is available for the `convert_x265` script. It provides detailed usage instructions, options, and examples.

### Viewing the Man Page

After installation, you can view the man page using the following command:

```bash
man convert_x265
```

The man page is installed in `/usr/share/man/man1/convert_x265.1.gz` and is automatically compressed during the installation process.

### Integration into Installation

The man page is now part of the installation process. When you build and install the `.deb` package using the `create_deb_package.sh` script, the man page is automatically placed in the appropriate directory (`/usr/share/man/man1/`) and compressed for use with the `man` command.

## Additional Scripts

- `check_x265.sh`: Checks for pending files that need to be processed. It logs the files that have not been processed yet and skips those that have the 'larger' attribute set.
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