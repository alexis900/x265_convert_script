# x265 Convert Script

This script converts video files to H265 (HEVC) format or changes their container if they are already in H265 but not in MKV format. If the estimated size of the file converted to H265 is larger than the original and the original codec is not H264, the file will be converted to H264 with the extension `.x264.mkv`.

## Requirements

- `ffmpeg`
- `ffprobe`
- `xattr` (optional, to mark files with extended attributes)

## Usage

1. Clone the repository or download the script.
2. Ensure the script has execution permissions:
    ```bash
    chmod +x convert_x265.sh
    ```
3. Create an `env.sh` file in the same directory as the script with the following variables:
    ```bash
    # env.sh
    actual_dir="/path/to/video/directory"
    log_file="/path/to/log/file/convert.log"
    ffmpeg_log_file="/path/to/log/file/ffmpeg.log"
    remaining_log="/path/to/log/file/remaining.log"
    ```
4. Run the script:
    ```bash
    ./convert_x265.sh
    ```

## Main Functions

- `log()`: Logs events with a timestamp to a log file and the screen.
- `backup_file()`: Creates a backup of the original file.
- `delete_backup()`: Deletes the backup of the original file.
- `detect_codec()`: Detects the video codec of the file.
- `has_valid_subtitles()`: Checks if the file has valid subtitles.
- `check_xattr_larger()`: Checks if the file has the 'larger' attribute.
- `mark_xattr_larger()`: Marks the file with the 'larger' attribute.
- `estimate_h265_size()`: Estimates the size of the file after conversion to H265.
- `verify_quality()`: Verifies the quality of the converted file.
- `convert_to_h265_or_change_container()`: Converts the file to H265 or changes the container. If the estimated size of the file converted to H265 is larger than the original and the original codec is not H264, the file will be converted to H264 with the extension `.x264.mkv`.

## Additional Script

- `check_x265.sh`: Checks for pending files that need to be processed.

## Notes

- The script searches for video files in the directory specified in `actual_dir` and processes them one by one.
- If no files are found to convert or change the container, the script exits.
- The script waits 10 seconds before searching for new files to process.

## License

This project is licensed under the terms of the MIT license.