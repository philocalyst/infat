// infat-lib/src/macos/launch_services_db.rs
//! Launch Services database parsing for the init command

use crate::error::{InfatError, Result};
use crate::macos::workspace::{self, resolve_to_bundle_id};
use plist::Value;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use tracing::{debug, info, warn};

#[derive(Debug, Deserialize, Serialize)]
pub struct LaunchServicesHandler {
    #[serde(rename = "LSHandlerContentType")]
    pub content_type: Option<String>,

    #[serde(rename = "LSHandlerContentTag")]
    pub content_tag: Option<String>,

    #[serde(rename = "LSHandlerContentTagClass")]
    pub content_tag_class: Option<String>,

    #[serde(rename = "LSHandlerURLScheme")]
    pub url_scheme: Option<String>,

    #[serde(rename = "LSHandlerRoleAll")]
    pub role_all: Option<String>,

    #[serde(rename = "LSHandlerRoleViewer")]
    pub role_viewer: Option<String>,

    #[serde(rename = "LSHandlerRoleEditor")]
    pub role_editor: Option<String>,

    #[serde(rename = "LSHandlerPreferredVersions")]
    pub preferred_versions: Option<HashMap<String, String>>,

    #[serde(rename = "LSHandlerModificationDate")]
    pub modification_date: Option<f64>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct LaunchServicesDatabase {
    #[serde(rename = "LSHandlers")]
    pub handlers: Vec<LaunchServicesHandler>,
}

/// Read the Launch Services database from the user's preferences
pub fn read_launch_services_database() -> Result<LaunchServicesDatabase> {
    let home = dirs::home_dir().ok_or_else(|| InfatError::LaunchServicesError {
        message: "Could not determine home directory".to_string(),
    })?;

    let ls_path = home
        .join("Library")
        .join("Preferences")
        .join("com.apple.LaunchServices")
        .join("com.apple.launchservices.secure.plist");

    debug!(
        "Reading Launch Services database from: {}",
        ls_path.display()
    );

    if !ls_path.exists() {
        return Err(InfatError::LaunchServicesError {
            message: format!(
                "Launch Services database not found at: {}",
                ls_path.display()
            ),
        });
    }

    let plist_data = std::fs::read(&ls_path)?;
    let value: Value =
        plist::from_bytes(&plist_data).map_err(|e| InfatError::LaunchServicesError {
            message: format!("Failed to parse Launch Services database: {e}"),
        })?;

    let db: LaunchServicesDatabase =
        plist::from_value(&value).map_err(|e| InfatError::LaunchServicesError {
            message: format!("Failed to deserialize Launch Services database: {e}"),
        })?;

    info!(
        "Successfully loaded Launch Services database with {} handlers",
        db.handlers.len()
    );

    Ok(db)
}

/// Generate a config from the current Launch Services database
pub fn generate_config_from_launch_services(robust: bool) -> Result<crate::config::Config> {
    let db = read_launch_services_database()?;

    let mut extensions = HashMap::new();
    let mut schemes = HashMap::new();
    let mut types = HashMap::new();
    let mut skipped_count = 0;
    let mut processed_count = 0;

    for handler in db.handlers {
        if let Some(bundle_id) = handler.role_all {
            // Skip malformed entries
            if bundle_id == "-" {
                debug!("Skipping malformed handler entry");
                skipped_count += 1;
                continue;
            }

            // Skip system services
            if crate::macos::workspace::is_system_service(&bundle_id) {
                debug!("Skipping system service: {}", bundle_id);
                skipped_count += 1;
                continue;
            }

            // Canonicalize the id
            let canonical_id = match resolve_to_bundle_id(&bundle_id) {
                Ok(id) => id,
                Err(_) => {
                    // couldn’t resolve, so skip or warn
                    if robust {
                        warn!("Skipping unresolved bundle id {:?}", bundle_id);
                        skipped_count += 1;
                        continue;
                    } else {
                        return Err(InfatError::ApplicationNotFound { name: bundle_id });
                    }
                }
            };

            let app_name = match workspace::get_app_name_from_bundle_id(&canonical_id) {
                Ok(name) => name,
                Err(e) => {
                    if robust {
                        warn!("Skipping {}: {}", canonical_id, e);
                        skipped_count += 1;
                        continue;
                    } else {
                        return Err(e);
                    }
                }
            };

            // Process different handler types
            if let Some(scheme) = handler.url_scheme {
                schemes.insert(scheme, app_name);
                processed_count += 1;
            } else if let Some(content_type) = handler.content_type {
                types.insert(content_type, app_name);
                processed_count += 1;
            } else if let Some(tag_class) = handler.content_tag_class {
                if tag_class == "public.filename-extension" {
                    if let Some(ext) = handler.content_tag {
                        extensions.insert(ext, app_name);
                        processed_count += 1;
                    }
                }
            }
        }
    }

    info!(
        "Processed {} handlers, skipped {} (system services/not found)",
        processed_count, skipped_count
    );

    Ok(crate::config::Config {
        extensions,
        schemes,
        types,
    })
}
