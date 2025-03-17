#!/bin/bash

SHARE_PATH="/usr/local/share/x265_convert_script"

# Directorio actual
source $SHARE_PATH/env.sh

# Verificar si los archivos necesarios existen
required_files=("env.sh")
for file in "${required_files[@]}"; do
    if [[ ! -f "$SHARE_PATH/$file" ]]; then
        echo "Error: El archivo requerido $file no existe. Saliendo..."
        exit 1
    fi
done

# Función para encontrar archivos pendientes
find_pending_files() {
    find "$actual_dir" -type f \
        \( -name "*.mkv" -o -name "*.avi" -o -name "*.mp4" -o -name "*.mov" -o -name "*.wmv" -o -name "*.flv" -o -name "*.m4v" -o -name "*.webm" -o -name "*.3gp" \) \
        -not -name "*.h265.mkv" -not -name "*.x265.mkv" | while read -r f; do
            codec=$(detect_codec "$f")
            xattr_output=$(check_xattr_larger "$f")
            if [[ "$codec" == "hevc" ]] && [[ "${f##*.}" != "mkv" ]]; then
                echo "$f"
            elif [[ "$codec" == "h264" ]] && [[ "${f##*.}" != "mkv" ]]; then
                echo "$f"
            elif [[ "$codec" != "hevc" && "$xattr_output" != "true" ]]; then
                echo "$f"
            fi
        done
}

# Función para detectar el codec de video del archivo
detect_codec() {
    ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$1"
}

# Función para verificar si el archivo tiene el atributo 'larger'
check_xattr_larger() {
    local file="$1"
    if command -v xattr &>/dev/null; then
        xattr -p user.larger "$file" 2>/dev/null
    else
        log "ERROR" "xattr no está disponible en este sistema" "$log_file"
        return 1
    fi
}

# Función para marcar el archivo con el atributo 'larger'
mark_xattr_larger() {
    local file="$1"
    if command -v xattr &>/dev/null; then
        xattr -w user.larger true "$file"
    else
        log "ERROR" "xattr no está disponible en este sistema" "$log_file"
    fi
}
