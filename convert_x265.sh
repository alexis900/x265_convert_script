#!/bin/bash

# Directorio actual y archivos de log
source ./env.sh
source ./logging.sh
source ./file_utils.sh

# Verificar si los archivos necesarios existen
required_files=("env.sh" "logging.sh" "file_utils.sh")
for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "Error: El archivo requerido $file no existe. Saliendo..."
        exit 1
    fi
done

# Parámetros comunes de ffmpeg
FFMPEG_PRESET="medium"
FFMPEG_CRF=22
FFMPEG_VIDEO_CODEC="libx265"
FFMPEG_AUDIO_CODEC="copy"
FFMPEG_SUBTITLE_CODEC="srt"
FFMPEG_LOG_LEVEL="error"

# Directorio de respaldo
BACKUP_DIR="$actual_dir/backup"

# Función para crear un respaldo del archivo original
backup_file() {
    local file="$1"
    mkdir -p "$BACKUP_DIR"
    cp "$file" "$BACKUP_DIR"
    log "INFO" "Respaldo creado para: $file" "$log_file"
}

# Función para eliminar el respaldo del archivo original
delete_backup() {
    local file="$1"
    local backup_file="$BACKUP_DIR/$(basename "$file")"
    if [[ -f "$backup_file" ]]; then
        rm "$backup_file"
        log "INFO" "Respaldo eliminado para: $file" "$log_file"
    fi
}

# Función para verificar si hay subtítulos válidos en el archivo
has_valid_subtitles() {
    ffprobe -v $FFMPEG_LOG_LEVEL -select_streams s -show_entries stream=codec_name -of csv=p=0 "$1" | grep -qE 'srt|subrip|ass|ssa'
}

# Función para estimar el tamaño del archivo después de la conversión a H265
estimate_h265_size() {
    local input_file="$1"
    local part_duration=10  # Duración en segundos para las partes
    local total_size=0
    rm -f /tmp/tmp_h265_part_*.mkv
    log "INFO" "Estimando tamaño para: $input_file" "$log_file"
    
    # Asegurarse de que el directorio /tmp existe
    mkdir -p /tmp

    # Convierte el archivo en 10 partes de 10 segundos para estimar el tamaño
    for i in $(seq 0 9); do
        local tmp_output="/tmp/tmp_h265_part_$i.mkv"
        log "INFO" "Procesando parte $i del archivo $input_file" "$log_file"

        ffmpeg -i "$input_file" -ss $((i * part_duration)) -t "$part_duration" -c:v libx265 -preset $FFMPEG_PRESET -crf $FFMPEG_CRF -c:a $FFMPEG_AUDIO_CODEC -sn -f matroska "$tmp_output" &>> "$ffmpeg_log_file"

        if [[ $? -ne 0 ]]; then
            log "ERROR" "Error en la conversión de la parte $i del archivo $input_file" "$log_file"
            cleanup_temp_files
            return 1
        fi

        # Sumar el tamaño de cada parte
        if [[ -f "$tmp_output" ]]; then
            local part_size=$(wc -c < "$tmp_output")
            total_size=$((total_size + part_size))
            log "INFO" "Parte $i procesada, tamaño: $part_size bytes" "$log_file"
        else
            log "ERROR" "No se pudo crear el archivo temporal $tmp_output" "$log_file"
            cleanup_temp_files
            return 1
        fi
    done

    # Eliminar todos los archivos temporales de una vez
    rm /tmp/tmp_h265_part_*.mkv

    log "INFO" "Tamaño total estimado para $input_file: $total_size bytes" "$log_file"
    
    echo "$total_size"
}

# Función para verificar la calidad del archivo convertido
verify_quality() {
    local input_file="$1"
    local output_file="$2"

    log "INFO" "Verificando calidad del archivo convertido: $output_file" "$log_file"

    # Compara la duración del archivo original y el convertido
    local original_duration=$(ffprobe -v $FFMPEG_LOG_LEVEL -show_entries format=duration -of csv=p=0 "$input_file")
    local converted_duration=$(ffprobe -v $FFMPEG_LOG_LEVEL -show_entries format=duration -of csv=p=0 "$output_file")

    if [[ $(echo "$original_duration == $converted_duration" | bc -l) -eq 1 ]]; then
        log "INFO" "La duración del archivo convertido coincide con el original." "$log_file"
    else
        log "WARNING" "La duración del archivo convertido no coincide con el original." "$log_file"
    fi
}

# Función para convertir el archivo a H265 o cambiar el contenedor
convert_to_h265_or_change_container() {
    local input_file="$1"
    local output_file="$2"
    local codec="$3"

    log "INFO" "Procesando archivo: $input_file" "$log_file"

    # Crear un respaldo del archivo original
    backup_file "$input_file"

    # Estimar el tamaño del archivo después de la conversión
    estimate_h265_size "$input_file"
    local estimated_size=$?
    local estimated_size=$(estimate_h265_size "$input_file")
    if [[ $? -ne 0 ]]; then
        log "ERROR" "Error en estimate_h265_size al estimar el tamaño del archivo $input_file" "$log_file"
        return 1
    fi
    log "INFO" "Tamaño estimado para el archivo después de conversión: $estimated_size bytes" "$log_file"

    local original_size=$(stat -c%s "$input_file")
    log "INFO" "Tamaño original del archivo: $original_size bytes" "$log_file"

    if (( estimated_size > original_size )) && [[ "$codec" != "h264" ]]; then
        log "INFO" "El tamaño estimado en H265 es mayor que el original y el codec no es H264. Convirtiendo a H264." "$log_file"
        FFMPEG_VIDEO_CODEC="libx264"
        output_file="$(dirname "$input_file")/$(basename "$input_file" | cut -d. -f1).x264.mkv"
    else
        FFMPEG_VIDEO_CODEC="libx265"
    fi

    if has_valid_subtitles "$input_file"; then
        log "INFO" "El archivo tiene subtítulos. Iniciando conversión con subtítulos." "$log_file"
        ffmpeg -i "$input_file" -map 0 -c:v $FFMPEG_VIDEO_CODEC -preset $FFMPEG_PRESET -crf $FFMPEG_CRF -c:a $FFMPEG_AUDIO_CODEC -c:s $FFMPEG_SUBTITLE_CODEC "$output_file" 2>> "$ffmpeg_log_file"
    else
        log "INFO" "El archivo no tiene subtítulos. Iniciando conversión sin subtítulos." "$log_file"
        ffmpeg -i "$input_file" -c:v $FFMPEG_VIDEO_CODEC -preset $FFMPEG_PRESET -crf $FFMPEG_CRF -c:a $FFMPEG_AUDIO_CODEC -sn "$output_file" 2>> "$ffmpeg_log_file"
    fi

    if [[ $? -eq 0 ]]; then
        log "INFO" "Conversión completada exitosamente: $output_file" "$log_file"
        if verify_quality "$input_file" "$output_file"; then
            log "INFO" "Eliminando archivo original: $input_file" "$log_file"
            rm "$input_file"
            delete_backup "$input_file"
        else
            log "WARNING" "La calidad del archivo convertido no es aceptable. Conservando el archivo original." "$log_file"
        fi
    else
        log "ERROR" "Error durante la conversión: $output_file" "$log_file"
        log "INFO" "Restaurando el archivo original desde el respaldo: $input_file" "$log_file"
        cp "$BACKUP_DIR/$(basename "$input_file")" "$input_file"
    fi
}

# Función para limpiar archivos temporales
cleanup_temp_files() {
    rm -f /tmp/tmp_h265_part_*.mkv
    log "INFO" "Archivos temporales eliminados" "$log_file"
}

# Función para manejar señales
handle_signal() {
    log "INFO" "Señal recibida, limpiando y saliendo..." "$log_file"
    cleanup_temp_files
    exit 1
}

# Registrar manejadores de señales
trap handle_signal SIGINT SIGTERM

process_file() {
    local file="$1"
    local codec=$(detect_codec "$file")
    if [[ -z "$codec" ]]; then
        log "ERROR" "Error: No se pudo detectar el codec del archivo $file" "$log_file"
        return 1
    fi
    local h265_path="$(dirname "$file")/$(basename "$file" | cut -d. -f1).x265.mkv"
    convert_to_h265_or_change_container "$file" "$h265_path" "$codec"
}

while true; do
    log "INFO" "Buscando archivos en $actual_dir..." "$log_file"

    files=$(find_pending_files)

    if [[ -z "$files" ]]; then
        log "INFO" "No se encontraron archivos para convertir o cambiar contenedor. Saliendo..." "$log_file"
        break
    fi

    while IFS= read -r file; do
        process_file "$file"
    done <<< "$files"

    log "INFO" "Esperando 10 segundos antes de la siguiente iteración..." "$log_file"
    sleep 10
done

exit 0