use anyhow::{Context, Result};
use clap::Parser;
use std::path::PathBuf;

mod file_utils;
mod media_utils;
mod logging;

use file_utils::{find_pending_files, process_file};
use logging::init_logging;

/// Simple x265 converter (partial rewrite in Rust - minimal MVP)
#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Input file or directory
    #[arg(short, long)]
    input: Option<PathBuf>,

    /// Output directory (optional)
    #[arg(short, long)]
    output: Option<PathBuf>,

    /// Preset for encoder
    #[arg(long, default_value = "medium")]
    preset: String,

    /// CRF value
    #[arg(long, default_value_t = 22)]
    crf: u8,

    /// Dry run
    #[arg(long, default_value_t = false)]
    dry_run: bool,

    /// Verbose
    #[arg(short, long, action = clap::ArgAction::Count)]
    verbose: u8,
}

fn main() -> Result<()> {
    let args = Args::parse();
    init_logging(args.verbose);

    let input = args.input.clone().unwrap_or_else(|| PathBuf::from("."));

    if input.is_file() {
        process_file(&input, &args, args.dry_run).context("processing file")?;
        return Ok(());
    }

    // Directory: find pending files
    let files = find_pending_files(&input)?;
    for f in files {
        process_file(&f, &args, args.dry_run).with_context(|| format!("processing {}", f.display()))?;
    }

    Ok(())
}
