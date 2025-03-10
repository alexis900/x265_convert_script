#!/bin/bash

# Directorio actual y archivo de log
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

log "INFO" "Verificando el directorio: $actual_dir" "$remaining_log"
if [ ! -d "$actual_dir" ]; then
    log "ERROR" "¡Error! El directorio $actual_dir no existe." "$remaining_log"
    exit 1
fi

log "INFO" "Buscando archivos pendientes..." "$remaining_log"

files_pending=$(find_pending_files)

# Comprobar si ya fueron procesados y si tienen el atributo 'larger'
while IFS= read -r file; do
    # Verificar si el archivo ya fue procesado
    xattr_output=$(check_xattr_larger "$file")

    # Si el archivo tiene el atributo 'larger', solo lo registramos en el log, sin mostrarlo en pantalla
    if [[ -n "$xattr_output" ]]; then
        continue
    else
        log "INFO" "Archivo pendiente para procesar: $file" "$remaining_log"
    fi
done <<< "$files_pending"

log "INFO" "Fin de la búsqueda de archivos pendientes." "$remaining_log"
