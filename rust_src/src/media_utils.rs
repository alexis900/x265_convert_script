use anyhow::{Context, Result};
use std::path::Path;

use crate::logging::{info, debug}; // si quieres varias funciones


pub fn detect_codec(path: &Path) -> Result<String> {
    let output = std::process::Command::new("ffprobe")
        .arg("-v")
        .arg("error")
        .arg("-select_streams")
        .arg("v:0")
        .arg("-show_entries")
        .arg("stream=codec_name")
        .arg("-of")
        .arg("default=nw=1:nk=1")
        .arg(path)
        .output()
        .context("running ffprobe")?;

    if !output.status.success() {
        anyhow::bail!("ffprobe failed");
    }

    let s = String::from_utf8_lossy(&output.stdout).trim().to_string();
    Ok(s)
}
