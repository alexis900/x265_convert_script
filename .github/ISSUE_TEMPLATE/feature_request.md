---
name: Feature request
about: Propose a new feature or improvement for the project
title: "## [#XX - Descriptive feature title]"
labels: enhancement
assignees: ''

---

**Creation date:** YYYY-MM-DD  
**Author:** @{{ github.actor }}
**Status:** ☐ Open ☐ In progress ☐ In review ☐ Closed  
**Type:** ☐ Enhancement ☐ Proposal ☐ New plugin

---

### 📝 Summary

Briefly describe the proposed feature or idea. Include the context, current limitations, and expected impact or benefit.

---

### ⚙️ Technical Details

- **Current behavior:** What happens today without this feature?
- **Expected behavior:** What should happen once it's implemented?
- **Affected components:** Files, modules, or scripts impacted (e.g., `convert_x265`, `file_utils.sh`, etc.)

---

### 💡 Implementation Proposal

Outline the technical plan or idea:
- Plugin logic (if applicable)
- Suggested file or directory structure
- Parameters or flags to be added
- External tools used (`ffmpeg`, `ffprobe`, etc.)

---

### ✅ Acceptance Criteria

- [ ] Feature works with both `--file` and `--dir` inputs.
- [ ] Compatible with all existing core scripts and plugins.
- [ ] Documentation and help updated.
- [ ] Error handling and logging integrated.

---

### 🚀 Usage Example

```bash
./convert.sh --plugin auto_profile --input "movie.mkv"
