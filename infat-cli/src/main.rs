// infat-cli/src/main.rs - COMPLETE IMPLEMENTATION
use clap::{Parser, Subcommand};
use color_eyre::{
    eyre::{Context, Result},
    owo_colors::OwoColorize,
};
use infat_lib::{
    app, association, config, macos::launch_services_db, uti::SuperType, GlobalOptions,
};
use std::path::PathBuf;
use tracing::{error, info};

#[derive(Parser, Debug, Clone)]
#[command(
    author,
    version,
    about = "Declaratively manage macOS file associations and URL schemes",
    long_about = "Infat allows you to inspect and modify default applications for file types \
                  and URL schemes on macOS. It supports declarative configuration through TOML \
                  files for reproducible setups across machines."
)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,

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
enum Commands {
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

#[tokio::main]
async fn main() -> Result<()> {
    // Install color-eyre for beautiful error reports
    color_eyre::install().wrap_err("Failed to install color-eyre error handler")?;

    let cli = Cli::parse();
    let global_opts: GlobalOptions = (&cli).into();

    // Initialize tracing
    infat_lib::init_tracing(&global_opts).wrap_err("Failed to initialize logging")?;

    // Handle commands
    match cli.command {
        None => {
            // No subcommand provided - load and apply configuration
            handle_config_load(&global_opts)
                .await
                .wrap_err("Failed to load and apply configuration")?;
        }
        Some(Commands::Info { app, ext, r#type }) => {
            handle_info_command(app, ext, r#type)
                .await
                .wrap_err("Info command failed")?;
        }
        Some(Commands::Set {
            app_name,
            ext,
            scheme,
            r#type,
        }) => {
            handle_set_command(&global_opts, app_name, ext, scheme, r#type)
                .await
                .wrap_err("Set command failed")?;
        }
        Some(Commands::Init { output }) => {
            handle_init_command(&global_opts, output)
                .await
                .wrap_err("Init command failed")?;
        }
    }

    Ok(())
}

async fn handle_config_load(opts: &GlobalOptions) -> Result<()> {
    let config_path = match &opts.config_path {
        Some(path) => {
            if !path.exists() {
                return Err(color_eyre::eyre::eyre!(
                    "Configuration file not found: {}",
                    path.display().bright_red()
                ));
            }
            path.clone()
        }
        None => config::find_config_file().ok_or_else(|| {
            color_eyre::eyre::eyre!(
                "No configuration file found. Use {} or place config at XDG location",
                "--config".bright_yellow()
            )
        })?,
    };

    if !opts.quiet {
        println!(
            "📄 Loading configuration from: {}",
            config_path.display().bright_cyan()
        );
    }

    let config = config::Config::from_file(&config_path).wrap_err_with(|| {
        format!(
            "Failed to load configuration from {}",
            config_path.display().bright_red()
        )
    })?;

    if config.is_empty() {
        return Err(color_eyre::eyre::eyre!(
            "Configuration file is empty or contains no valid tables"
        ));
    }

    let summary = config.summary();
    if !opts.quiet {
        println!(
            "📊 Found {} associations: {} extensions, {} schemes, {} types",
            summary.total().to_string().bright_green(),
            summary.extensions_count,
            summary.schemes_count,
            summary.types_count
        );
    }

    // Apply configuration
    config::apply_config(&config, opts.robust)
        .await
        .wrap_err("Failed to apply configuration settings")?;

    if !opts.quiet {
        println!("{}", "✅ Configuration applied successfully".bright_green());
    }

    Ok(())
}

async fn handle_info_command(
    app: Option<String>,
    ext: Option<String>,
    r#type: Option<String>,
) -> Result<()> {
    let provided_count = [app.is_some(), ext.is_some(), r#type.is_some()]
        .iter()
        .filter(|&&x| x)
        .count();

    if provided_count == 0 {
        return Err(color_eyre::eyre::eyre!(
            "Must provide one of: {}, {}, or {}",
            "--app".bright_yellow(),
            "--ext".bright_yellow(),
            "--type".bright_yellow()
        ));
    }

    if provided_count > 1 {
        return Err(color_eyre::eyre::eyre!(
            "Only one of {}, {}, or {} may be provided",
            "--app".bright_yellow(),
            "--ext".bright_yellow(),
            "--type".bright_yellow()
        ));
    }

    if let Some(app_name) = app {
        info!("Getting info for application: {}", app_name);

        let app_info = app::get_app_info(&app_name)
            .wrap_err_with(|| format!("Failed to get info for app: {}", app_name))?;

        // Display application information
        println!("{}", "Application Information".bright_blue().bold());
        println!("  Name: {}", app_info.name.bright_cyan());
        println!("  Bundle ID: {}", app_info.bundle_id.bright_green());
        println!("  Version: {}", app_info.version);
        println!("  Path: {}", app_info.path.display().dimmed());

        // Display declared URL schemes
        if !app_info.declared_schemes.is_empty() {
            println!("\n{}", "Declared URL Schemes:".bright_blue().bold());
            for scheme in &app_info.declared_schemes {
                println!("  • {}", scheme.bright_yellow());
            }
        }

        // Display declared file types
        if !app_info.declared_types.is_empty() {
            println!("\n{}", "Declared File Types:".bright_blue().bold());
            for declared_type in &app_info.declared_types {
                println!("  • {}", declared_type.name.bright_cyan());

                if !declared_type.utis.is_empty() {
                    println!("    UTIs: {}", declared_type.utis.join(", ").dimmed());
                }

                if !declared_type.extensions.is_empty() {
                    let exts: Vec<String> = declared_type
                        .extensions
                        .iter()
                        .map(|ext| format!(".{}", ext))
                        .collect();
                    println!("    Extensions: {}", exts.join(", ").bright_green());
                }

                if let Some(desc) = &declared_type.description {
                    println!("    Description: {}", desc.italic());
                }
                println!();
            }
        }
    } else if let Some(extension) = ext {
        info!("Getting info for extension: .{}", extension);

        let info = association::get_info_for_extension(&extension)
            .wrap_err_with(|| format!("Failed to get info for extension: .{}", extension))?;

        println!(
            "📄 File Extension: {}",
            format!(".{}", extension).bright_green()
        );

        if let Some(uti) = &info.uti {
            println!("   UTI: {}", uti.bright_cyan());
        }

        match info.default_app_name()? {
            Some(app_name) => {
                println!("   Default app: {}", app_name.bright_yellow());
            }
            None => {
                println!("   Default app: {}", "None".bright_red());
            }
        }

        let all_app_names = info.all_app_names();
        if !all_app_names.is_empty() {
            println!("\n{}", "All registered apps:".bright_blue().bold());
            for app_name in all_app_names {
                println!("  • {}", app_name);
            }
        } else {
            println!(
                "\n{}",
                "No applications registered for this extension".yellow()
            );
        }
    } else if let Some(type_name) = r#type {
        info!("Getting info for type: {}", type_name);

        let info = association::get_info_for_type(&type_name)
            .wrap_err_with(|| format!("Failed to get info for type: {}", type_name))?;

        println!("🏷️  File Type: {}", type_name.bright_green());

        if let Some(uti) = &info.uti {
            println!("    UTI: {}", uti.bright_cyan());
        }

        match info.default_app_name()? {
            Some(app_name) => {
                println!("    Default app: {}", app_name.bright_yellow());
            }
            None => {
                println!("    Default app: {}", "None".bright_red());
            }
        }

        let all_app_names = info.all_app_names();
        if !all_app_names.is_empty() {
            println!("\n{}", "All registered apps:".bright_blue().bold());
            for app_name in all_app_names {
                println!("  • {}", app_name);
            }
        } else {
            println!("\n{}", "No applications registered for this type".yellow());
        }
    }

    Ok(())
}

async fn handle_set_command(
    opts: &GlobalOptions,
    app_name: String,
    ext: Option<String>,
    scheme: Option<String>,
    r#type: Option<String>,
) -> Result<()> {
    let provided_count = [ext.is_some(), scheme.is_some(), r#type.is_some()]
        .iter()
        .filter(|&&x| x)
        .count();

    if provided_count == 0 {
        return Err(color_eyre::eyre::eyre!(
            "Must provide one of: {}, {}, or {}",
            "--ext".bright_yellow(),
            "--scheme".bright_yellow(),
            "--type".bright_yellow()
        ));
    }

    if provided_count > 1 {
        return Err(color_eyre::eyre::eyre!(
            "Only one of {}, {}, or {} may be provided",
            "--ext".bright_yellow(),
            "--scheme".bright_yellow(),
            "--type".bright_yellow()
        ));
    }

    if let Some(extension) = ext {
        info!("Setting {} as default for .{}", app_name, extension);

        association::set_default_app_for_extension(&extension, &app_name)
            .await
            .wrap_err_with(|| format!("Failed to set default app for .{}", extension))?;

        if !opts.quiet {
            println!(
                "{} Set .{} → {}",
                "✓".bright_green(),
                extension,
                app_name.bright_cyan()
            );
        }
    } else if let Some(url_scheme) = scheme {
        info!("Setting {} as default for {} scheme", app_name, url_scheme);

        association::set_default_app_for_url_scheme(&url_scheme, &app_name)
            .await
            .wrap_err_with(|| format!("Failed to set default app for {} scheme", url_scheme))?;

        if !opts.quiet {
            println!(
                "{} Set {} → {}",
                "✓".bright_green(),
                url_scheme,
                app_name.bright_cyan()
            );
        }
    } else if let Some(type_name) = r#type {
        info!("Setting {} as default for type {}", app_name, type_name);

        association::set_default_app_for_type(&type_name, &app_name)
            .await
            .wrap_err_with(|| format!("Failed to set default app for type {}", type_name))?;

        if !opts.quiet {
            println!(
                "{} Set type {} → {}",
                "✓".bright_green(),
                type_name,
                app_name.bright_cyan()
            );
        }
    }

    Ok(())
}

async fn handle_init_command(opts: &GlobalOptions, output: Option<PathBuf>) -> Result<()> {
    info!("Initializing configuration from Launch Services database");

    if !opts.quiet {
        println!("🔍 Reading Launch Services database...");
    }

    let config = launch_services_db::generate_config_from_launch_services(opts.robust)
        .wrap_err("Failed to generate configuration from Launch Services database")?;

    let summary = config.summary();

    if !opts.quiet {
        println!(
            "📊 Generated {} associations: {} extensions, {} schemes, {} types",
            summary.total().to_string().bright_green(),
            summary.extensions_count,
            summary.schemes_count,
            summary.types_count
        );
    }

    // Determine output path
    let output_path = match output {
        Some(path) => path,
        None => match &opts.config_path {
            Some(path) => path.clone(),
            None => {
                let paths = config::get_config_paths();
                paths
                    .first()
                    .ok_or_else(|| color_eyre::eyre::eyre!("Could not determine config path"))?
                    .clone()
            }
        },
    };

    if !opts.quiet {
        println!(
            "💾 Writing configuration to: {}",
            output_path.display().bright_cyan()
        );
    }

    config
        .to_file(&output_path)
        .wrap_err_with(|| format!("Failed to write configuration to {}", output_path.display()))?;

    if !opts.quiet {
        println!(
            "{}",
            "✅ Configuration initialized successfully".bright_green()
        );
        println!("To apply these settings, run: {}", "infat".bright_yellow());
    }

    Ok(())
}
