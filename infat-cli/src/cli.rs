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
        /// Application name to inspect
        #[arg(short, long, value_name = "APP")]
        app: Option<String>,

        /// File extension (without dot)
        #[arg(short, long, value_name = "EXT")]
        ext: Option<String>,

        /// File type/supertype
        #[arg(short, long, value_name = "TYPE")]
        r#type: Option<String>,
    },

    /// Set an application association
    Set {
        /// Application name or bundle identifier
        #[arg(value_name = "APP")]
        app_name: String,

        /// File extension (without dot)
        #[arg(long, value_name = "EXT")]
        ext: Option<String>,

        /// URL scheme
        #[arg(long, value_name = "SCHEME")]
        scheme: Option<String>,

        /// File type/supertype
        #[arg(long, value_name = "TYPE")]
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
