// infat-lib/src/config.rs
use crate::{
    association,
    error::{InfatError, Result},
};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use tracing::{debug, info, warn};

#[derive(Debug, Serialize, Deserialize, Default, Clone)]
pub struct Config {
    #[serde(default, skip_serializing_if = "HashMap::is_empty")]
    pub extensions: HashMap<String, String>,

    #[serde(default, skip_serializing_if = "HashMap::is_empty")]
    pub schemes: HashMap<String, String>,

    #[serde(default, skip_serializing_if = "HashMap::is_empty")]
    pub types: HashMap<String, String>,
}

#[derive(Debug, Clone)]
pub struct ConfigSummary {
    pub extensions_count: usize,
    pub schemes_count: usize,
    pub types_count: usize,
}

impl ConfigSummary {
    pub fn total(&self) -> usize {
        self.extensions_count + self.schemes_count + self.types_count
    }
}

impl Config {
    /// Load configuration from a TOML file
    pub fn from_file<P: AsRef<Path>>(path: P) -> Result<Self> {
        let path = path.as_ref();

        let content = fs::read_to_string(path)?;
        let config: Self = toml::from_str(&content)?;

        Ok(config)
    }

    /// Save configuration to a TOML file
    pub fn to_file<P: AsRef<Path>>(&self, path: P) -> Result<()> {
        let path = path.as_ref();

        // Create parent directories if they don't exist
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)?;
        }

        let content = toml::to_string_pretty(self)?;
        fs::write(path, content)?;

        Ok(())
    }

    /// Check if the configuration is empty
    pub fn is_empty(&self) -> bool {
        self.extensions.is_empty() && self.schemes.is_empty() && self.types.is_empty()
    }

    /// Validate the configuration
    pub fn validate(&self) -> Result<()> {
        if self.is_empty() {
            return Err(InfatError::NoConfigTables {
                path: PathBuf::from("<config>"),
            });
        }

        // Check for invalid keys in types
        for type_name in self.types.keys() {
            // Try parsing as SuperType or assume it's a UTI
            if type_name.parse::<crate::uti::SuperType>().is_err() && !type_name.contains('.') {
                warn!("Type '{}' may not be a valid UTI or supertype", type_name);
            }
        }

        Ok(())
    }

    /// Get summary statistics
    pub fn summary(&self) -> ConfigSummary {
        ConfigSummary {
            extensions_count: self.extensions.len(),
            schemes_count: self.schemes.len(),
            types_count: self.types.len(),
        }
    }
}

/// Get XDG-compliant configuration file paths in order of preference
pub fn get_config_paths() -> Vec<std::path::PathBuf> {
    let mut paths = Vec::new();

    // User config directory ($XDG_CONFIG_HOME or ~/.config)
    if let Some(config_dir) = dirs::config_dir() {
        paths.push(config_dir.join("infat").join("config.toml"));
    }

    // System config directories from $XDG_CONFIG_DIRS or fallback
    let xdg_config_dirs =
        std::env::var("XDG_CONFIG_DIRS").unwrap_or_else(|_| "/etc/xdg".to_string());

    for dir in xdg_config_dirs.split(':') {
        if !dir.is_empty() {
            paths.push(
                std::path::PathBuf::from(dir)
                    .join("infat")
                    .join("config.toml"),
            );
        }
    }

    paths
}

/// Find the first existing configuration file
pub fn find_config_file() -> Option<std::path::PathBuf> {
    get_config_paths().into_iter().find(|path| path.exists())
}

/// Apply configuration settings
pub async fn apply_config(config: &Config, robust: bool) -> Result<()> {
    info!("Applying configuration settings");

    config.validate()?;

    let summary = config.summary();
    info!(
        "Configuration contains {} total associations",
        summary.total()
    );

    let mut errors = Vec::new();
    let mut success_count = 0;

    // Apply types first
    if !config.types.is_empty() {
        info!(
            "Processing [types] associations ({} entries)...",
            config.types.len()
        );
        for (type_name, app_name) in &config.types {
            match association::set_default_app_for_type(type_name, app_name).await {
                Ok(_) => {
                    info!("✓ Set type {} → {}", type_name, app_name);
                    success_count += 1;
                }
                Err(e) => {
                    let msg = format!("Failed to set type {type_name} → {app_name}: {e}");
                    if robust {
                        warn!("{}", msg);
                        errors.push(msg);
                    } else {
                        return Err(e);
                    }
                }
            }
        }
    }

    // Apply extensions
    if !config.extensions.is_empty() {
        info!(
            "Processing [extensions] associations ({} entries)...",
            config.extensions.len()
        );
        for (ext, app_name) in &config.extensions {
            match association::set_default_app_for_extension(ext, app_name).await {
                Ok(_) => {
                    info!("✓ Set .{} → {}", ext, app_name);
                    success_count += 1;
                }
                Err(e) => {
                    let msg = format!("Failed to set .{ext} → {app_name}: {e}");
                    if robust {
                        warn!("{}", msg);
                        errors.push(msg);
                    } else {
                        return Err(e);
                    }
                }
            }
        }
    }

    // Apply schemes
    if !config.schemes.is_empty() {
        info!(
            "Processing [schemes] associations ({} entries)...",
            config.schemes.len()
        );
        for (scheme, app_name) in &config.schemes {
            match association::set_default_app_for_url_scheme(scheme, app_name).await {
                Ok(_) => {
                    info!("✓ Set {} → {}", scheme, app_name);
                    success_count += 1;
                }
                Err(e) => {
                    let msg = format!("Failed to set {scheme} → {app_name}: {e}");
                    if robust {
                        warn!("{}", msg);
                        errors.push(msg);
                    } else {
                        return Err(e);
                    }
                }
            }
        }
    }

    info!(
        "Configuration applied: {} successful, {} errors",
        success_count,
        errors.len()
    );

    if !errors.is_empty() && robust {
        warn!(
            "Configuration applied with {} errors in robust mode",
            errors.len()
        );
        for (i, error) in errors.iter().enumerate() {
            debug!("  Error {}: {}", i + 1, error);
        }
    }

    Ok(())
}
