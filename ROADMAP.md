# Phase 1: Refactoring and Usability (v0.1.x)

**Goal:** Improve argument handling and multi-file support  
**Tasks**

- Replace argument parsing with `getopts` or similar in `convert_x265`
- Add directory support (process files recursively)
- Implement options:

    ```
    --input <file|dir>
    --output <file|dir>
    --preset <ultrafast|medium|slow>
    --crf <int>
    --dry-run
    --verbose
    --help
    ```

- Validate input files: process only valid videos (check extension and MIME type)
- Show simple progress in console for each file
- Update README with new options and examples

**Checkpoints**

- Script accepts multiple files and folders
- Script ignores invalid files and shows a warning
- `--dry-run` option does not perform conversion but shows the plan
- `--help` and `--verbose` options work correctly
- Documentation updated

---

# Phase 2: Robustness and Security (v0.2.x)

**Goal:** Improve error handling and add backups  
**Tasks**

- Add detailed error handling in `convert_x265` and auxiliary functions (capture ffmpeg failures, permissions, etc.)
- Add automatic backups before overwriting with `backup.sh`
- Implement automatic restoration on errors
- Support SIGINT (Ctrl+C) interrupts, cleaning processes and temporary files
- Validate environment and dependencies (`ffmpeg`, `ffprobe`) with `check_x265`
- Add configurable logging in `logging.sh` with levels (INFO, WARN, ERROR, DEBUG)
- Validate permissions and disk space before operations (`file_utils.sh`)

**Checkpoints**

- Backup created before any overwrite
- On critical error, automatic restoration works
- Ctrl+C interrupt cleans state and leaves no corrupted files
- Logs saved with timestamps and severity level
- Environment check lists all dependencies and shows warnings

---

# Phase 3: Performance and Automation (v0.3.x)

**Goal:** Improve performance and automate decisions  
**Tasks**

- Implement parallel processing controlling number of threads (`--parallel <n>`)
- Use `media_utils.sh` to extract metadata with `ffprobe` (codec, bitrate, resolution)
- Dynamically adjust CRF and preset parameters based on metadata and profile
- Add predefined presets (ultrafast, medium, slow) and allow custom presets
- Improve `import_files.sh` for filters by extension, size, and dates
- Add log rotation in `logging.sh` to avoid large files
- Implement CPU usage control to avoid saturation

**Checkpoints**

- Multiprocessing works without collisions or errors
- Parameters automatically adjusted per input video
- Import filters work correctly and efficiently
- Logs rotate when exceeding size limit
- CPU usage control limits processes properly

---

# Phase 4: Extensibility and Maintenance (v0.4.x)

**Goal:** Facilitate future improvements and maintenance  
**Tasks**

- Modularize code: well-separated functions and organized auxiliary scripts
- Create automated tests for key functions (bash unit tests or BATS)
- Improve MIME functions and path handling in `file_utils.sh`
- Integrate semantic version control (`version` + `check_update.sh`)
- Add configuration file for default parameters (`x265_convert.conf`)

**Checkpoints**

- Modular and easy-to-extend codebase
- Automated tests cover >70% of key functions
- External configuration functional and documented
- Version updated correctly and update check works

---

# Phase 5: Documentation and Support (v0.5.x)

**Goal:** Improve user experience and support  
**Tasks**

- Complete README with advanced examples and step-by-step tutorials
- Add FAQ with common problems and solutions
- Document all functions, variables, and scripts
- Create quick start guide for interested developers
- Add usage examples in shell scripts

**Checkpoints**

- Complete and well-structured README
- FAQ solves >80% of common questions
- Documentation generated for all main functions
- Developer guide available and clear

---

# Phase 6: Stable Release 1.0

**Goal:** Consolidate and release stable version  
**Tasks**

- Perform comprehensive testing (unit tests, use cases, stress tests)
- Optimize code and fix detected bugs
- Confirm compatibility across different environments (Debian, Ubuntu, etc.)
- Document roadmap for future improvements (plugins, GUI, notifications)
- Tag version 1.0 in repo and prepare release notes

**Checkpoints**

- All critical features run without errors
- Automated tests pass successfully
- Documentation updated and consistent
- Official release available on GitHub
