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

# Function to convert the file to H265 or change the container
convert_to_h265_or_change_container() {
    local input_file="$1"
    local output_file="$2"
    local codec="$3"

    log "INFO" "Processing file: $input_file" "${LOG_FILE}"

    # Create a backup of the original file
    backup_file "$input_file"

    # Estimate the size of the file after conversion
    log "DEBUG" "Estimating size for $input_file" "${LOG_FILE}"
    local estimated_size
    estimated_size=$(estimate_video_size "$input_file") || return 1
    log "INFO" "Estimated size for the file after conversion: $estimated_size bytes" "${LOG_FILE}"

    local original_size=$(stat -c%s "$input_file")
    log "INFO" "Original file size: $original_size bytes" "${LOG_FILE}"

    if (( estimated_size > original_size )) && [[ "$codec" != "h264" ]]; then
        log "INFO" "The estimated size in H265 is larger than the original and the codec is not H264. Converting to H264." "${LOG_FILE}"
        VIDEO_CODEC="libx264"
        output_file=$(get_output_path "$input_file" "x264")
    else
        VIDEO_CODEC="libx265"
    fi

    if has_valid_subtitles "$input_file"; then
        video_convert "$input_file" "$output_file" "$VIDEO_CODEC" "$SUBTITLE_CODEC" "$AUDIO_CODEC"
    else
        video_convert "$input_file" "$output_file" "$VIDEO_CODEC" "" "$AUDIO_CODEC"
    fi

    if [[ $? -eq 0 ]]; then
        log "INFO" "Conversion completed successfully: $output_file" "${LOG_FILE}"
        if verify_quality "$input_file" "$output_file"; then
            log "INFO" "Deleting original file: $input_file" "${LOG_FILE}"
            rm "$input_file"
            delete_backup "$input_file"
        else
            log "WARNING" "The quality of the converted file is not acceptable. Keeping the original file." "${LOG_FILE}"
            mark_xattr_skip "$input_file"
        fi
    else
        log "ERROR" "Error during conversion: $output_file" "${LOG_FILE}"
        log "INFO" "Restoring the original file from backup: $input_file" "${LOG_FILE}"
        cp "$(backup_path_for_file "$input_file")" "$input_file"
    fi
}

# Function to estimate the size of the file after conversion to H265
# Parameters:
#   $1 - The input video file to estimate the size for.
estimate_video_size() {
    local input_file="$1"
    local part_duration=5  # Duration in seconds for parts
    local total_size=0
    local total_parts=5 # Number of parts to split the file into
    local total_duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$input_file" | cut -d. -f1)
    local tmp_dir

    tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/x265_estimate.XXXXXX")" || {
        log "ERROR" "Could not create temporary directory for estimation." "${LOG_FILE}"
        return 1
    }
    trap 'rm -rf "$tmp_dir"' RETURN

    log "INFO" "Estimating size for: $input_file" "${LOG_FILE}" >&2

    # Convert the file in 10 parts of 10 seconds to estimate the size
    for i in $(seq 0 $((total_parts - 1))); do
        local tmp_output="${tmp_dir}/part_${i}.${OUTPUT_EXTENSION}"
        log "DEBUG" "Processing part $i of file $input_file" "${LOG_FILE}" >&2

        ffmpeg -y -nostdin -i "$input_file" -ss $((i * part_duration)) -t "$part_duration" -c:v "$VIDEO_CODEC" -preset "$PRESET" -crf "$CRF" -c:a "$AUDIO_CODEC" -sn -f matroska "$tmp_output" &>> "${FFMPEG_LOG_FILE}"

        if [[ $? -ne 0 ]]; then
            log "ERROR" "Error converting part $i of file $input_file. FFmpeg output: $(cat "${FFMPEG_LOG_FILE}")" "${LOG_FILE}" >&2
            return 1
        fi

        # Sum the size of each part
        if [[ -f "$tmp_output" ]]; then
            local part_size=$(wc -c < "$tmp_output")
            total_size=$((total_size + part_size))
            log "DEBUG" "Part $i processed, size: $(human_size $total_size)" "${LOG_FILE}" >&2
        else
            log "ERROR" "Could not create temporary file $tmp_output" "${LOG_FILE}" >&2
            return 1
        fi
    done

    if [[ -z "$total_duration" || "$total_duration" -eq 0 ]]; then
        log "ERROR" "Invalid total duration for $input_file. Cannot estimate size." "${LOG_FILE}" >&2
        return 1
    fi

    # Adjustment: the estimation is proportional to the size of the converted parts relative to the total duration

    estimated_size=$(( total_size * total_duration / (part_duration * total_parts) ))
    log "INFO" "Total estimated size for $input_file: $(human_size $estimated_size)" "${LOG_FILE}" >&2
    echo "$estimated_size"
}

load_profile () {
    local profile="$1"
    local profile_file="$SRC_PATH/profiles/${profile}.conf"
    if [[ -f $profile_file ]]; then
        source "$profile_file"
        log "DEBUG" "Loaded profile: $profile_file" "${LOG_FILE}"
    else
        log "ERROR" "Profile file not found: $profile_file" "${LOG_FILE}"
        return 1
    fi

    if [[ ${DEBUG} == true ]]; then
        echo "PRESET: $PRESET"
        echo "CRF: $CRF"
        echo "VIDEO_CODEC: $VIDEO_CODEC"
        echo "AUDIO_CODEC: $AUDIO_CODEC"
        echo "AUDIO_BITRATE: $AUDIO_BITRATE"
        echo "SUBTITLE_CODEC: $SUBTITLE_CODEC"
        echo "PIX_FMT: $PIX_FMT"
        echo "TUNE: $TUNE"
        echo "EXTRA_OPTS: $EXTRA_OPTS"
    fi
}


export -f has_valid_subtitles
export -f detect_codec
export -f verify_quality
export -f video_convert
export -f load_profile
export -f convert_to_h265_or_change_container
export -f estimate_video_size
