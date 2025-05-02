#!/bin/bash

# Function to check if the file has valid subtitles
has_valid_subtitles() {
    ffprobe -v $FFMPEG_LOG_LEVEL -select_streams s -show_entries stream=codec_name -of csv=p=0 "$1" | grep -qE 'srt|subrip|ass|ssa'
}

# Function to detect the video codec of the file
detect_codec() {
    ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$1"
}

# Function to verify the quality of the converted file
verify_quality() {
    local input_file="$1"
    local output_file="$2"

    log "INFO" "Verifying quality of converted file: $output_file" "${LOG_FILE}"

    # Compare the duration of the original and converted files
    local original_duration=$(ffprobe -v $FFMPEG_LOG_LEVEL -show_entries format=duration -of csv=p=0 "$input_file")
    local converted_duration=$(ffprobe -v $FFMPEG_LOG_LEVEL -show_entries format=duration -of csv=p=0 "$output_file")

    if [[ $(echo "$original_duration == $converted_duration" | bc -l) -eq 1 ]]; then
        log "INFO" "The duration of the converted file matches the original." "${LOG_FILE}"
    else
        log "WARNING" "The duration of the converted file does not match the original." "${LOG_FILE}"
    fi
}

# Function to convert a video file
# Parameters:
#   $1 - Input file
#   $2 - Output file
#   $3 - Video codec (e.g., libx265 or libx264)
#   $4 - Subtitle codec (optional, pass empty if no subtitles)
video_convert() {
    local input_file="$1"
    local output_file="$2"
    local video_codec="$3"
    local subtitle_codec="$4"

    if [[ -n "$subtitle_codec" ]]; then
        log "INFO" "Starting conversion with subtitles for: $input_file" "${LOG_FILE}"
        ffmpeg -i "$input_file" -map 0 -c:v "$video_codec" -preset "$FFMPEG_PRESET" -crf "$FFMPEG_CRF" -c:a "$FFMPEG_AUDIO_CODEC" -c:s "$subtitle_codec" "$output_file" &>> "$ffmpeg_log_file"
    else
        log "INFO" "Starting conversion without subtitles for: $input_file" "${LOG_FILE}"
        ffmpeg -i "$input_file" -map 0 -c:v "$video_codec" -preset "$FFMPEG_PRESET" -crf "$FFMPEG_CRF" -c:a "$FFMPEG_AUDIO_CODEC" -sn "$output_file" &>> "$ffmpeg_log_file"
    fi

    if [[ $? -eq 0 ]]; then
        log "INFO" "Conversion successful: $output_file" "${LOG_FILE}"
        return 0
    else
        log "ERROR" "Conversion failed for: $input_file" "${LOG_FILE}"
        return 1
    fi
}

export -f has_valid_subtitles
export -f detect_codec
export -f verify_quality
export -f video_convert