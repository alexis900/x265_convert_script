# Revisión de Código - x265_convert_script

## 📋 Resumen Ejecutivo

El proyecto está bien estructurado con código Bash y Rust. He identificado **15+ áreas de mejora** en seguridad, rendimiento, mantenibilidad y calidad del código. Abajo está el análisis detallado.

---

## 🔴 CRÍTICAS (Seguridad y Funcionalidad)

### 1. **Error Handling Frágil en Rust**
**Archivo:** [rust_src/src/main.rs](rust_src/src/main.rs)
- **Problema:** `unwrap_or_else` silencia errores sin logging
- **Impacto:** Difícil debuggear problemas en producción
- **Solución:**
```rust
let input = args.input.clone().unwrap_or_else(|| {
    warn!("No input specified, using current directory");
    PathBuf::from(".")
});
```

### 2. **Rutas Hardcodeadas en Bash**
**Archivo:** [src/lib/backup.sh](src/lib/backup.sh#L1-L30)
- **Problema:** `/tmp/tmp_h265_part_*` es inseguro y específico del sistema
- **Impacto:** Riesgo de privacidad, colisiones con otros procesos
- **Solución:** Usar `mktemp -d` o `$TMPDIR`
```bash
TEMP_DIR=$(mktemp -d) || exit 1
trap "rm -rf $TEMP_DIR" EXIT
```

### 3. **Validación de Entrada Deficiente**
**Archivo:** [src/lib/arguments.sh](src/lib/arguments.sh#L1-L12)
- **Problema:** `check_input()` no valida rutas antes de procesarlas
- **Solución:** Agregar validaciones de seguridad
```bash
check_input() {
    local input="$1"
    # Validar ruta canónica
    if ! realpath "$input" >/dev/null 2>&1; then
        log "ERROR" "Path does not exist: $input" "${LOG_FILE}"
        return 1
    fi
    # ...resto del código
}
```

### 4. **Inyección de Comandos en ffmpeg**
**Archivo:** [src/lib/media_utils.sh](src/lib/media_utils.sh#L47-L65)
- **Problema:** Variables sin comillas pueden causar inyección de comandos
- **Riesgo:** Si `$subtitle_codec` o `$audio_codec` contienen caracteres especiales
```bash
# ❌ MALO - Sin comillas
ffmpeg -y -i "$input_file" -c:a $audio_codec ...

# ✅ BUENO - Con comillas
ffmpeg -y -i "$input_file" -c:a "$audio_codec" ...
```

### 5. **Race Condition en Archivos de Backup**
**Archivo:** [src/lib/backup.sh](src/lib/backup.sh#L4-L10)
- **Problema:** Multiples conversiones simultáneas pueden sobrescribir backups
- **Solución:** Usar timestamps o UUIDs
```bash
backup_file() {
    local file="$1"
    mkdir -p "${BACKUP_DIR}"
    cp "$file" "${BACKUP_DIR}/$(basename "$file").$(date +%s)"
    log "INFO" "Backup created for: $file" "${LOG_FILE}"
}
```

---

## 🟠 MAYORES (Mantenibilidad y Rendimiento)

### 6. **Duplicación de Código**
**Archivos:** [convert_x265](src/bin/convert_x265#L70-L150) y [media_utils.sh](src/lib/media_utils.sh#L150-L230)
- **Problema:** `estimate_video_size()` y `convert_to_h265_or_change_container()` están en 2 lugares
- **Solución:** Consolidar en `media_utils.sh` solamente

### 7. **Gestión de Errores Inconsistente en Rust**
**Archivo:** [rust_src/src/media_utils.rs](rust_src/src/media_utils.rs)
- **Problema:** `detect_codec()` solo retorna `String` vacío en error, sin contexto
- **Mejor:** Usar tipos Rust nativos
```rust
pub fn detect_codec(path: &Path) -> Result<String> {
    let output = std::process::Command::new("ffprobe")
        // ...
        .output()
        .context("failed to execute ffprobe")?;

    // Validar exit status PRIMERO
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        anyhow::bail!("ffprobe failed: {}", stderr);
    }
    // ...
}
```

### 8. **Configuración Hardcodeada**
**Archivo:** [src/config/preferences.conf](src/config/preferences.conf)
- **Problema:** `ACTUAL_DIR="/tmp/test"` es un placeholder que va a producción
- **Solución:** Usar valores por defecto sensatos o requerir configuración
```bash
# Usar defaults seguros
ACTUAL_DIR="${ACTUAL_DIR:-$HOME/Videos}"
```

### 9. **Logs Distribuidos sin Consolidación**
**Archivo:** [src/config/preferences.conf](src/config/preferences.conf#L3-L5)
- **Problema:** 3 archivos de log diferentes, difícil de seguir
- **Solución:** Un solo archivo con niveles de log diferentes
```bash
LOG_FILE="${HOME}/.cache/x265_convert/logs/x265_convert.log"
# Único archivo para todo
```

### 10. **Exit Codes Inconsistentes**
**Archivo:** [src/lib/file_utils.sh](src/lib/file_utils.sh)
- **Problema:** Algunos errores retornan 1, otros 2, otros no retornan nada
- **Solución:** Definir convención
```bash
# Definir al inicio del script
readonly EXIT_OK=0
readonly EXIT_GENERAL_ERROR=1
readonly EXIT_MISSING_DEPENDENCY=2
readonly EXIT_INVALID_INPUT=3
```

---

## 🟡 MODERADAS (Calidad y Eficiencia)

### 11. **Ciclo de Eventos Ineficiente**
**Archivo:** [src/bin/convert_x265](src/bin/convert_x265#L210+)
- **Problema:** Loop `while true` con `sleep $SLEEP_TIME` es poco escalable
- **Mejor:** Usar `inotify` para cambios de archivo o `systemd` timer
```bash
# Considerar usar inotifywait para produccción
inotifywait -m -r -e create "$ACTUAL_DIR" | while read path action file; do
    process_file "$path/$file"
done
```

### 12. **Estimación de Tamaño Ineficiente**
**Archivo:** [src/bin/convert_x265](src/bin/convert_x265#L72-L120) y [src/lib/media_utils.sh](src/lib/media_utils.sh#L150+)
- **Problema:** Convierte 5 partes de 5 segundos = **25 segundos de procesamiento** solo para estimar
- **Impacto:** Lentitud extrema para videos largos
- **Mejor:** Usar bitrate + duración total
```bash
estimate_video_size() {
    local file="$1"
    # Obtener bitrate promedio de 10 segundos
    ffmpeg -t 10 -i "$file" -f null - 2>&1 | grep bitrate | awk '{print $NF}' # mucho más rápido
}
```

### 13. **Falta de Logging en Rust**
**Archivo:** [rust_src/src/logging.rs](rust_src/src/logging.rs)
- **Problema:** Sistema de logging muy básico, sin integración con syslog
- **Solución:** Usar crate `log` o `tracing`
```toml
[dependencies]
log = "0.4"
env_logger = "0.10"
```

### 14. **Manejo Incompleto de Dependencias**
**Archivo:** Múltiples archivos bash
- **Problema:** No verifica si `ffmpeg`, `xattr`, `bc`, `numfmt` están instalados
- **Solución:** 
```bash
check_dependencies() {
    local deps=("ffmpeg" "ffprobe" "xattr" "bc" "numfmt")
    for cmd in "${deps[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || {
            log "ERROR" "Required command not found: $cmd" "${LOG_FILE}"
            exit 2
        }
    done
}

check_dependencies
```

### 15. **Tests Incompletos**
**Archivo:** [src/tests/test_convert_x265.sh](src/tests/test_convert_x265.sh)
- **Problema:** Archivo existe pero no está implementado (asumo)
- **Solución:** Agregar tests unitarios para funciones críticas
```bash
test_detect_codec() {
    # Test con archivo real
    local codec=$(detect_codec "test_files/sample.mp4")
    [[ "$codec" == "h264" ]] || exit 1
}
```

---

## 🟢 MENORES (Estilo y Mejoras)

### 16. **Scripts sin Shebang o Inconsistentes**
- Agregar `#!/usr/bin/env bash` a todos los `.sh` files
- **Por qué:** Portabilidad y claridad

### 17. **Variables Globales sin Prefijo**
**Archivos:** Bash scripts
- **Problema:** `LOG_LEVEL`, `PRESET` son globales sin prefijo
- **Solución:** Usar prefijo para legibilidad
```bash
# Mejor
declare -g X265_LOG_LEVEL="DEBUG"
declare -g X265_PRESET="medium"
```

### 18. **Documentación de Funciones Incompleta**
- Muchas funciones bash no tienen docstring
- **Solución:** Agregar documentación estándar
```bash
# Description: Convert video file to H265 format
# Arguments: $1=input_file $2=output_file $3=preset
# Returns: 0 on success, 1 on failure
video_convert() {
    # ...
}
```

### 19. **Archivos de Configuración sin Validación**
**Archivo:** [src/config/preferences.conf](src/config/preferences.conf)
- **Problema:** No se valida que variables requeridas estén presentes
- **Solución:** Schema de validación al cargar la config
```bash
load_config() {
    source "$CONFIG_FILE"
    # Validar variables requeridas
    for var in PRESET CRF OUTPUT_EXTENSION; do
        [[ -z "${!var}" ]] && {
            log "ERROR" "Required config variable $var not set" "${LOG_FILE}"
            exit 1
        }
    done
}
```

### 20. **Tipos en Rust Poco Descriptivos**
**Archivo:** [rust_src/src/main.rs](rust_src/src/main.rs)
- **Problema:** Usar `u8` para `verbose` cuando `u32` es más estándar
- **Impacto:** Menor, pero inconsistente
```rust
#[arg(short, long, action = clap::ArgAction::Count)]
verbose: u8,  // Debería ser u32 como el default de clap
```

---

## 📊 Resumen de Mejoras por Prioridad

| Prioridad | Cantidad | Ejemplos |
|-----------|----------|----------|
| 🔴 Crítica | 5 | Inyección de comandos, rutas inseguras, race conditions |
| 🟠 Mayor | 5 | Duplicación de código, error handling, configuración |
| 🟡 Moderada | 5 | Eficiencia, logging, tests |
| 🟢 Menor | 5 | Estilo, documentación, tipos |

---

## ✅ Lo que Está Bien

1. ✅ Estructura modular clara (separación en `lib/`, `bin/`, `config/`)
2. ✅ Manejo de perfiles de configuración
3. ✅ Sistema de backup implementado
4. ✅ Verificación de calidad post-conversión
5. ✅ Soporte para múltiples formatos de video
6. ✅ Signal handlers para limpieza graceful
7. ✅ Makefile con verificación de sintaxis
8. ✅ Atributos extendidos (xattr) para marcar archivos procesados

---

## 🎯 Recomendaciones de Próximos Pasos

1. **Inmediato:** Fijar las 5 vulnerabilidades críticas de seguridad
2. **Corto plazo:** Consolidar duplicación de código y mejorar testing
3. **Mediano plazo:** Reescribir en Rust completamente (eliminar Bash)
4. **Largo plazo:** Agregar API REST y Web UI

---

## 📝 Notas

- El código Bash es funcional pero frágil para producción
- La integración Rust/Bash es innecesaria (elegir uno)
- Considerar usar `parallel` para procesar múltiples archivos simultáneamente
- Agregar telemetría/métricas para monitoreo

