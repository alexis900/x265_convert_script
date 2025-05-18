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
    local tolerance=0.5  # segundos de tolerancia

    log "INFO" "Verifying quality of converted file: $output_file" "${LOG_FILE}"

    # Compare the duration of the original and converted files
    local original_duration=$(ffprobe -v $FFMPEG_LOG_LEVEL -show_entries format=duration -of csv=p=0 "$input_file")
    local converted_duration=$(ffprobe -v $FFMPEG_LOG_LEVEL -show_entries format=duration -of csv=p=0 "$output_file")

    if [[ -z "$original_duration" || -z "$converted_duration" ]]; then
        log "ERROR" "Could not get duration for quality check." "${LOG_FILE}"
        return 1
    fi

    # Calcula la diferencia absoluta
    local diff
    diff=$(echo "$original_duration - $converted_duration" | bc -l)
    diff=$(echo "${diff#-}")  # valor absoluto

    if (( $(echo "$diff < $tolerance" | bc -l) )); then
        log "INFO" "Duration matches within tolerance ($tolerance s)." "${LOG_FILE}"
        return 0
    else
        log "WARNING" "Duration differs by more than $tolerance s." "${LOG_FILE}"
        return 1
    fi
}

# Function to convert a video file
# Parameters:
#   $1 - Input file
#   $2 - Output file
#   $3 - Video codec (e.g., libx265 or libx264)
#   $4 - Subtitle codec (optional, pass empty if no subtitles)
#   $5 - Audio codec (e.g., aac, ac3, etc.)
video_convert() {
    local input_file="$1"
    local output_file="$2"
    local video_codec="$3"
    local subtitle_codec="$4"
    local audio_codec="$5"

    log "INFO" "Preparing to convert video: $input_file" "${LOG_FILE}"

    # Check if the input file exists
    if [[ ! -f "$input_file" ]]; then
        log "ERROR" "Input file does not exist: $input_file" "${LOG_FILE}"
        return 1
    fi

    # Check if the video codec is provided
    if [[ -z "$video_codec" ]]; then
        log "ERROR" "No video codec specified for conversion." "${LOG_FILE}"
        return 1
    fi

    # Check if the audio codec is provided
    if [[ -z "$audio_codec" ]]; then
        log "ERROR" "No audio codec specified for conversion." "${LOG_FILE}"
        return 1
    fi

    if [[ -n "$subtitle_codec" ]]; then
        log "INFO" "Starting conversion with subtitles for: $input_file" "${LOG_FILE}"
        ffmpeg -y -i "$input_file" -map 0 -c:v "$video_codec" -preset "$PRESET" -crf "$CRF" -c:a "$audio_codec" -c:s "$subtitle_codec" "$output_file" &>> "${FFMPEG_LOG_FILE}"
    else
        log "INFO" "Starting conversion without subtitles for: $input_file" "${LOG_FILE}"
        ffmpeg -y -i "$input_file" -map 0 -c:v "$video_codec" -preset "$PRESET" -crf "$CRF" -c:a "$audio_codec" -sn "$output_file" &>> "${FFMPEG_LOG_FILE}"
    fi

    if [[ $? -eq 0 ]]; then
        log "INFO" "Conversion successful: $output_file" "${LOG_FILE}"
        return 0
    else
        log "ERROR" "Conversion failed for: $input_file" "${LOG_FILE}"
        return 1
    fi
}

load_profile () {
    local profile="$1"
    local profile_file="$SRC_PATH/profiles/${profile}.conf"
    if [[ -f $profile_file ]]; then
        source "$profile_file"
    else
        log "ERROR" "Profile file not found: $profile_file" "${LOG_FILE}"
        return 1
    fi

    echo "Loaded profile: $profile_file"
    echo "PRESET: $PRESET"
    echo "CRF: $CRF"
    echo "VIDEO_CODEC: $VIDEO_CODEC"
    echo "AUDIO_CODEC: $AUDIO_CODEC"
    echo "AUDIO_BITRATE: $AUDIO_BITRATE"
    echo "SUBTITLE_CODEC: $SUBTITLE_CODEC"
    echo "PIX_FMT: $PIX_FMT"
    echo "TUNE: $TUNE"
    echo "EXTRA_OPTS: $EXTRA_OPTS"
}


export -f has_valid_subtitles
export -f detect_codec
export -f verify_quality
export -f video_convert
export -f load_profile