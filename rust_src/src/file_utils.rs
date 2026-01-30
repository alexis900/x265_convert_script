use crate::logging::info;
use anyhow::{Context, Result};
use std::fs;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

use crate::media_utils::detect_codec;

// ArgsShim was a placeholder during early scaffolding and is currently unused.
// Removed to silence dead-code warnings; reintroduce if needed later.

pub fn find_pending_files(dir: &Path) -> Result<Vec<PathBuf>> {
    let mut res = Vec::new();
    let exts = ["mkv", "avi", "mp4", "mov", "wmv", "flv", "m4v", "webm", "3gp"];
    for entry in WalkDir::new(dir).follow_links(true).into_iter().filter_map(|e| e.ok()) {
        let p = entry.path();
        if p.is_file() {
            if let Some(ext) = p.extension().and_then(|s| s.to_str()) {
                if exts.contains(&ext) {
                    let codec = detect_codec(p).unwrap_or_else(|_| "".to_string());
                    if codec != "hevc" {
                        res.push(p.to_path_buf());
                    }
                }
            }
        }
    }
    Ok(res)
}

pub fn get_output_path(input: &Path, codec_suffix: &str) -> PathBuf {
    let stem = input.file_stem().and_then(|s| s.to_str()).unwrap_or("out");
    let dir = input.parent().unwrap_or_else(|| Path::new("."));
    dir.join(format!("{}.{}.mkv", stem, codec_suffix))
}

pub fn backup_file(input: &Path, backup_dir: &Path) -> Result<PathBuf> {
    fs::create_dir_all(backup_dir).with_context(|| format!("create backup dir {}", backup_dir.display()))?;
    let dest = backup_dir.join(input.file_name().unwrap());
    fs::copy(input, &dest).with_context(|| format!("copy to {}", dest.display()))?;
    info(&format!("Backup created: {} -> {}", input.display(), dest.display()));
    Ok(dest)
}

pub fn process_file(path: &Path, args: &crate::Args, dry_run: bool) -> Result<()> {
    let codec = detect_codec(path).unwrap_or_else(|_| "".to_string());
    info(&format!("Processing {} (detected: {})", path.display(), codec));
    if dry_run {
        info(&format!("Dry-run: would process {}", path.display()));
        return Ok(());
    }

    // Simple wrapper: call ffmpeg to convert to libx265
    let out = get_output_path(path, "x265");
    let backup_dir = Path::new("/tmp/backup");
    backup_file(path, backup_dir)?;

    let mut cmd = std::process::Command::new("ffmpeg");
        cmd.arg("-y").arg("-i").arg(path).arg("-c:v").arg("libx265").arg("-preset").arg(&args.preset).arg("-crf").arg(args.crf.to_string()).arg("-c:a").arg("copy").arg(&out);
    let status = cmd.status().context("running ffmpeg")?;
    if !status.success() {
        anyhow::bail!("ffmpeg failed");
    }

    Ok(())
}
