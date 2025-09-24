use clap::{CommandFactory, ValueEnum};
use clap_complete::{generate_to, Shell};
use std::{env, error::Error, fs, path::Path};

include!("src/cli.rs");

fn main() -> Result<(), Box<dyn Error>> {
    // Always re-run if OUT_DIR or build.rs or your CLI model changes:
    println!("cargo:rerun-if-env-changed=OUT_DIR");
    println!("cargo:rerun-if-changed=build.rs");
    println!("cargo:rerun-if-changed=src/main.rs");

    // grab OUT_DIR
    let out_dir = PathBuf::from(env::var("OUT_DIR")?);
    println!("OUT_DIR = {}", out_dir.display());

    // grab PROFILE ("debug" or "release")
    let profile = env::var("PROFILE")?;
    println!("PROFILE = {}", profile);

    // walk up ancestors until we find the profile directory
    let mut candidate: &Path = out_dir.as_path();
    let dest = loop {
        if let Some(name) = candidate.file_name().and_then(|s| s.to_str()) {
            if name == profile {
                break candidate.to_path_buf();
            }
        }
        candidate = candidate
            .parent()
            .ok_or("could not locate `debug` or `release` in OUT_DIR")?;
    };

    println!("writing completions into `{}`", dest.display());

    // make sure destination directory exists
    fs::create_dir_all(&dest)?;

    // generate completions
    let bin_name = env!("CARGO_PKG_NAME");
    let mut cmd = Cli::command();

    for &shell in Shell::value_variants() {
        match generate_to(shell, &mut cmd, bin_name, &dest) {
            Ok(path) => {
                println!("  • {:?} -> {}", shell, path.display());
            }
            Err(e) => {
                println!("failed to generate {:?}: {}", shell, e);
            }
        }
    }

    Ok(())
}
