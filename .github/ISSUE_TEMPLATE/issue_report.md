---
name: Feature request
about: Report a feature in the project
title: "## [#XX - Título descriptivo de la issue]"
labels: enhancement
assignees: ''

---

**Fecha de creación:** YYYY-MM-DD
**Autor:** @usuario  
**Estado:** Abierta | Cerrada | En revisión | En desarrollo  
**Tipo:** Mejora | Bug | Refactorización | Propuesta | Plugin nuevo  

---

### Resumen

Descripción clara y concisa del problema o propuesta. Incluye el contexto general y el objetivo principal.

---

### Detalles técnicos

- **Comportamiento actual:** ¿Qué ocurre actualmente en el script?
- **Comportamiento esperado:** ¿Qué debería ocurrir después de aplicar esta mejora o solución?
- **Componentes afectados:** Archivos, funciones, comandos o módulos relacionados.

---

### Propuesta de implementación

Pasos sugeridos, enfoque técnico o ideas para resolver la issue. Puede incluir:

- lógica del plugin
- estructura de carpetas o archivos
- uso de parámetros
- uso de herramientas externas (`ffprobe`, `mediainfo`, etc.)

---

### Criterios de aceptación

- [ ] Se selecciona automáticamente el perfil adecuado.
- [ ] No re-encodea archivos ya compatibles.
- [ ] Compatible con otros plugins existentes.
- [ ] Documentación actualizada.

---

### Ejemplos de uso

```bash
# Ejemplo práctico de cómo se usaría la solución
./convert.sh --plugin auto_profile --input "pelicula.mkv"
