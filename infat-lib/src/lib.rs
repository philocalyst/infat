#![allow(unexpected_cfgs)]
//! Infat - Declarative macOS file association and URL scheme management
//!
//! This library provides functionality to inspect and modify default applications
//! for file types and URL schemes on macOS using Launch Services.

pub mod app;
pub mod association;
pub mod config;
pub mod error;
pub mod uti;

#[cfg(target_os = "macos")]
pub mod macos {
    pub mod ffi;
    pub mod launch_services;
    pub mod launch_services_db;
    pub mod workspace;
}

pub use error::{InfatError, Result};

/// Global configuration and runtime options
#[derive(Debug, Clone, Default)]
pub struct GlobalOptions {
    pub config_path: Option<std::path::PathBuf>,
    pub verbose: bool,
    pub quiet: bool,
    pub robust: bool,
}

/// Initialize tracing subscriber based on global options
pub fn init_tracing(opts: &GlobalOptions) -> eyre::Result<()> {
    use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt, EnvFilter};

    let filter = if opts.verbose {
        EnvFilter::new("trace")
    } else if opts.quiet {
        EnvFilter::new("error")
    } else {
        EnvFilter::new("warn")
    };

    tracing_subscriber::registry()
        .with(filter)
        .with(tracing_subscriber::fmt::layer())
        .try_init()
        .map_err(|e| eyre::eyre!("Failed to initialize tracing subscriber: {}", e))?;

    Ok(())
}
