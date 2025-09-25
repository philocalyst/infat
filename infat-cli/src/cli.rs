use clap::{Parser, Subcommand};
use infat_lib::GlobalOptions;
use std::path::PathBuf;

#[derive(Parser, Debug, Clone)]
#[command(
    author,
    version,
    about = "Declaratively manage macOS file associations and URL schemes",
    long_about = "Infat allows you to inspect and modify default applications for file types \
                  and URL schemes on macOS. It supports declarative configuration through TOML \
                  files for reproducible setups across machines."
)]
pub(crate) struct Cli {
    #[command(subcommand)]
    pub(crate) command: Option<Commands>,

    /// Path to the configuration file
    #[arg(short, long, value_name = "PATH")]
    config: Option<PathBuf>,

    /// Enable verbose logging
    #[arg(short, long)]
    verbose: bool,

    /// Suppress all output except errors
    #[arg(short, long)]
    quiet: bool,

    /// Continue processing on errors when possible
    #[arg(long)]
    robust: bool,
}

#[derive(Subcommand, Debug, Clone)]
pub(crate) enum Commands {
    /// Show file association information
    Info {
        /// Show information for a specific application
        #[arg(long, conflicts_with_all = ["ext", "scheme", "type"])]
        app: Option<String>,

        /// Show information for a file extension
        #[arg(long, conflicts_with_all = ["app", "scheme", "type"])]
        ext: Option<String>,

        /// Show information for a URL scheme
        #[arg(long, conflicts_with_all = ["app", "ext", "type"])]
        scheme: Option<String>,

        /// Show information for a file type
        #[arg(long, conflicts_with_all = ["app", "ext", "scheme"])]
        r#type: Option<String>,
    },

    /// Set default application for file extension, URL scheme, or file type
    Set {
        /// Application name to set as default
        app_name: String,

        /// File extension to associate (without the dot)
        #[arg(long, conflicts_with_all = ["scheme", "type"])]
        ext: Option<String>,

        /// URL scheme to associate
        #[arg(long, conflicts_with_all = ["ext", "type"])]
        scheme: Option<String>,

        /// File type to associate
        #[arg(long, conflicts_with_all = ["ext", "scheme"])]
        r#type: Option<String>,
    },

    /// Initialize configuration from current Launch Services settings
    Init {
        /// Output configuration file path (defaults to XDG config location)
        #[arg(short, long, value_name = "PATH")]
        output: Option<PathBuf>,
    },
}

impl From<&Cli> for GlobalOptions {
    fn from(cli: &Cli) -> Self {
        Self {
            config_path: cli.config.clone(),
            verbose: cli.verbose,
            quiet: cli.quiet,
            robust: cli.robust,
        }
    }
}
