use clap::Parser;
use color_eyre::{
    eyre::{Context, Result},
    owo_colors::OwoColorize,
};
use infat_lib::{app, association, config, macos::launch_services_db, GlobalOptions};
use std::path::PathBuf;
use tracing::info;

mod cli;

use cli::{Cli, Commands};

#[tokio::main]
async fn main() -> Result<()> {
    // Color eyre for them goooood errors
    color_eyre::install().wrap_err("Failed to install color-eyre error handler")?;

    let cli = Cli::parse();
    let global_opts: GlobalOptions = (&cli).into();

    // Initialize tracing
    infat_lib::init_tracing(&global_opts).wrap_err("Failed to initialize logging")?;

    // Handle commands
    match cli.command {
        None => {
            // No subcommand provided - load and apply configuration
            // Kind of bespoke behavior but infat stands for infatuate
            // I like to think it's just running the verb
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
                "No configuration file found. Use {} or place config at default location",
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

    // Some basic validation that clap can't provide
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
            .wrap_err_with(|| format!("Failed to get info for app: {app_name}"))?;

        // Display application information
        println!("{}", "Application Information".bright_blue().bold());
        println!("  Name: {}", app_info.name.bright_cyan());
        println!("  Bundle ID: {}", app_info.bundle_id.bright_green());
        println!("  Version: {}", app_info.version);
        println!("  Path: {}", app_info.path.display().dimmed());

        // Declared means just those it claims to support

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
                        .map(|ext| format!(".{ext}"))
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
            .wrap_err_with(|| format!("Failed to get info for extension: .{extension}"))?;

        println!(
            "📄 File Extension: {}",
            format!(".{extension}").bright_green()
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
                println!("  • {app_name}");
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
            .wrap_err_with(|| format!("Failed to get info for type: {type_name}"))?;

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
                println!("  • {app_name}");
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
            .wrap_err_with(|| format!("Failed to set default app for .{extension}"))?;

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
            .wrap_err_with(|| format!("Failed to set default app for {url_scheme} scheme"))?;

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
            .wrap_err_with(|| format!("Failed to set default app for type {type_name}"))?;

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
