#!/bin/bash

# Directorio actual y archivo de log
source ./env.sh

# Función de log para registrar eventos con timestamp, en archivo y en pantalla
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$remaining_log"
}

# Función para leer el atributo 'larger'
check_xattr_larger() {
    local file="$1"
    xattr -p user.larger "$file" 2>/dev/null
}

# Verificar si la ruta del directorio es correcta
log "Verificando el directorio: $actual_dir"
if [ ! -d "$actual_dir" ]; then
    log "¡Error! El directorio $actual_dir no existe."
    exit 1
fi

log "Buscando archivos pendientes..."

# Buscar archivos que no estén procesados y tengan un formato soportado
files_pending=$(find "$actual_dir" -type f \
    \( -name "*.mkv" -o -name "*.avi" -o -name "*.mp4" -o -name "*.mov" -o -name "*.wmv" -o -name "*.flv" -o -name "*.m4v" -o -name "*.webm" -o -name "*.3gp" \) \
    -not -name "*.h265.mkv" -not -name "*.x265.mkv")

# Comprobar si ya fueron procesados y si tienen el atributo 'larger'
while IFS= read -r file; do
    # Verificar si el archivo ya fue procesado
        xattr_output=$(check_xattr_larger "$file")

        # Si el archivo tiene el atributo 'larger', solo lo registramos en el log, sin mostrarlo en pantalla
        if [[ -n "$xattr_output" ]]; then
            continue
        else
            log "Archivo pendiente para procesar: $file"
        fi
done <<< "$files_pending"

log "Fin de la búsqueda de archivos pendientes."
