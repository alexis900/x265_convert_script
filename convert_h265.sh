#!/bin/bash

# Directorio actual y archivos de log
actual_dir="/mnt/4TB/Multimedia/Peliculas"
log_file="/home/amartinper/convert_log.txt"
ffmpeg_log_file="/home/amartinper/ffmpeg_log.txt"

# Función de log para registrar eventos con timestamp, en archivo y en pantalla
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$log_file"
}

# Función para detectar el codec de video del archivo
detect_codec() {
    ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$1"
}

# Función para verificar si hay subtítulos válidos en el archivo
has_valid_subtitles() {
    ffprobe -v error -select_streams s -show_entries stream=codec_name -of csv=p=0 "$1" | grep -qE 'srt|subrip|ass|ssa'
}

# Función para verificar si el archivo tiene el atributo 'larger'
check_xattr_larger() {
    local file="$1"
    if command -v xattr &>/dev/null; then
        xattr -p user.larger "$file" 2>/dev/null
    else
        log "xattr no está disponible en este sistema"
        return 1
    fi
}

# Función para marcar el archivo con el atributo 'larger'
mark_xattr_larger() {
    local file="$1"
    if command -v xattr &>/dev/null; then
        xattr -w user.larger true "$file"
    else
        log "xattr no está disponible en este sistema"
    fi
}

# Función para estimar el tamaño del archivo después de la conversión a H265
estimate_h265_size() {
    local input_file="$1"
    local part_duration=10  # Duración en segundos para las partes
    local total_size=0

    log "Estimando tamaño para: $input_file"
    # Convierte el archivo en 10 partes de 10 segundos para estimar el tamaño
    for i in $(seq 0 9); do
        local tmp_output="/tmp/tmp_h265_part_$i.mkv"
        log "Procesando parte $i del archivo $input_file"

        ffmpeg -i "$input_file" -ss $((i * part_duration)) -t "$part_duration" -c:v libx265 -preset "medium" -crf 22 -c:a copy -sn -f matroska "$tmp_output" &>/dev/null

        if [[ $? -ne 0 ]]; then
            log "Error en la conversión de la parte $i del archivo $input_file"
            return 1
        fi

        # Sumar el tamaño de cada parte
        local part_size=$(stat -c%s "$tmp_output")
        total_size=$((total_size + part_size))

        log "Parte $i procesada, tamaño: $part_size bytes"

        # Eliminar el archivo temporal de la parte convertida
        rm "$tmp_output"
    done

    log "Tamaño total estimado para $input_file: $total_size bytes"
    
    # Retorna el tamaño estimado basado en 10 partes
    echo "$total_size"
}

# Función para convertir el archivo a H265 o cambiar el contenedor
convert_to_h265_or_change_container() {
    local input_file="$1"
    local output_file="$2"
    local codec="$3"

    log "Procesando archivo: $input_file"

    # Estimar el tamaño del archivo después de la conversión
    local estimated_size=$(estimate_h265_size "$input_file")
    log "Tamaño estimado para el archivo después de conversión: $estimated_size bytes"

    if has_valid_subtitles "$input_file"; then
        log "El archivo tiene subtítulos. Iniciando conversión a H265 con subtítulos."
        ffmpeg -i "$input_file" -map 0 -c:v libx265 -preset "medium" -crf 22 -c:a copy -c:s srt "$output_file" 2>> "$ffmpeg_log_file"
    else
        log "El archivo no tiene subtítulos. Iniciando conversión a H265 sin subtítulos."
        ffmpeg -i "$input_file" -c:v libx265 -preset "medium" -crf 22 -c:a copy -sn "$output_file" 2>> "$ffmpeg_log_file"
    fi

    if [[ $? -eq 0 ]]; then
        log "Conversión completada exitosamente: $output_file"
    else
        log "Error durante la conversión: $output_file"
    fi
}

while true; do
    log "Buscando archivos en $actual_dir..."

    file=$(find "$actual_dir" -type f \
        \( -name "*.mkv" -o -name "*.avi" -o -name "*.mp4" -o -name "*.mov" -o -name "*.wmv" -o -name "*.flv" -o -name "*.m4v" -o -name "*.webm" -o -name "*.3gp" \) \
        -not -name "*.h265.mkv" -not -name "*.x265.mkv" | while read -r f; do
            codec=$(detect_codec "$f")
            xattr_output=$(check_xattr_larger "$f")
            if [[ "$codec" == "hevc" ]] && [[ "${f##*.}" != "mkv" ]]; then
                echo "$f"; break
            elif [[ "$codec" == "h264" ]] && [[ "${f##*.}" != "mkv" ]]; then
                echo "$f"; break
            elif [[ "$codec" != "hevc" && "$xattr_output" != "true" ]]; then
                echo "$f"; break
            fi
        done)

    if [[ -z "$file" ]]; then
        log "No se encontraron archivos para convertir o cambiar contenedor. Saliendo..."
        break
    fi

    h265_path="$(dirname "$file")/$(basename "$file" | cut -d. -f1).x265.mkv"
    convert_to_h265_or_change_container "$file" "$h265_path" "$(detect_codec "$file")"

    log "Esperando 10 segundos antes de la siguiente iteración..."
    sleep 10
done
