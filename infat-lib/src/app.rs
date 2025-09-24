// infat-lib/src/app.rs
//! Application information and management

use crate::{
    error::{InfatError, Result},
    macos::workspace,
};
use plist::Value;
use std::path::PathBuf;
use tracing::{debug, warn};

/// Information about an application's declared file types and URL schemes
#[derive(Debug, Clone)]
pub struct AppInfo {
    pub bundle_id: String,
    pub name: String,
    pub version: String,
    pub path: PathBuf,
    pub declared_types: Vec<DeclaredType>,
    pub declared_schemes: Vec<String>,
}

/// A file type or UTI declared by an application
#[derive(Debug, Clone)]
pub struct DeclaredType {
    pub name: String,
    pub utis: Vec<String>,
    pub extensions: Vec<String>,
    pub description: Option<String>,
}

/// Get detailed information about an application
pub fn get_app_info(app_name_or_bundle_id: &str) -> Result<AppInfo> {
    debug!("Getting app info for: {}", app_name_or_bundle_id);

    // Find the application
    let app_path = workspace::find_application(app_name_or_bundle_id)?.ok_or_else(|| {
        InfatError::ApplicationNotFound {
            name: app_name_or_bundle_id.to_string(),
        }
    })?;

    // Get bundle ID
    let bundle_id = workspace::get_bundle_id_from_app_path(&app_path)?;

    // Read Info.plist
    let info_plist_path = app_path.join("Contents").join("Info.plist");
    let plist_data = std::fs::read(&info_plist_path)?;
    let plist: Value = plist::from_bytes(&plist_data).map_err(|e| InfatError::PlistReadError {
        path: info_plist_path.clone(),
        source: Box::new(e),
    })?;

    let dict = plist
        .as_dictionary()
        .ok_or_else(|| InfatError::PlistReadError {
            path: info_plist_path.clone(),
            source: "Info.plist root is not a dictionary".into(),
        })?;

    // Get app name
    let name = dict
        .get("CFBundleDisplayName")
        .or_else(|| dict.get("CFBundleName"))
        .and_then(|val| val.as_string())
        .unwrap_or("Unknown")
        .to_string();

    // Get version
    let version = dict
        .get("CFBundleShortVersionString")
        .or_else(|| dict.get("CFBundleVersion"))
        .and_then(|val| val.as_string())
        .unwrap_or("Unknown")
        .to_string();

    // Parse declared document types
    let declared_types = parse_document_types(&dict);

    // Parse declared URL schemes
    let declared_schemes = parse_url_schemes(&dict);

    Ok(AppInfo {
        bundle_id,
        name,
        version,
        path: app_path,
        declared_types,
        declared_schemes,
    })
}

/// Get the bundle ID for an application
pub fn get_app_bundle_id(app_name_or_path: &str) -> Result<String> {
    debug!("Getting bundle ID for: {}", app_name_or_path);

    if app_name_or_path.contains('.') && !app_name_or_path.contains('/') {
        // Already looks like a bundle ID
        return Ok(app_name_or_path.to_string());
    }

    workspace::resolve_to_bundle_id(app_name_or_path)
}

/// Get the version of an application
pub fn get_app_version(app_name_or_bundle_id: &str) -> Result<String> {
    let app_info = get_app_info(app_name_or_bundle_id)?;
    Ok(app_info.version)
}

/// Find application paths for a bundle identifier
pub fn get_app_paths_for_bundle_id(bundle_id: &str) -> Result<Vec<PathBuf>> {
    workspace::get_app_paths_for_bundle_id(bundle_id)
}

fn parse_document_types(info_dict: &plist::Dictionary) -> Vec<DeclaredType> {
    let mut declared_types = Vec::new();

    if let Some(doc_types) = info_dict
        .get("CFBundleDocumentTypes")
        .and_then(|v| v.as_array())
    {
        for doc_type in doc_types {
            if let Some(type_dict) = doc_type.as_dictionary() {
                let name = type_dict
                    .get("CFBundleTypeName")
                    .and_then(|v| v.as_string())
                    .unwrap_or("Unknown Type")
                    .to_string();

                let description = type_dict
                    .get("CFBundleTypeDescription")
                    .and_then(|v| v.as_string())
                    .map(|s| s.to_string());

                // Get UTIs
                let utis = if let Some(uti_array) = type_dict
                    .get("LSItemContentTypes")
                    .and_then(|v| v.as_array())
                {
                    uti_array
                        .iter()
                        .filter_map(|v| v.as_string())
                        .map(|s| s.to_string())
                        .collect()
                } else {
                    Vec::new()
                };

                // Get file extensions
                let extensions = if let Some(ext_array) = type_dict
                    .get("CFBundleTypeExtensions")
                    .and_then(|v| v.as_array())
                {
                    ext_array
                        .iter()
                        .filter_map(|v| v.as_string())
                        .map(|s| s.to_string())
                        .collect()
                } else {
                    Vec::new()
                };

                declared_types.push(DeclaredType {
                    name,
                    utis,
                    extensions,
                    description,
                });
            }
        }
    }

    declared_types
}

fn parse_url_schemes(info_dict: &plist::Dictionary) -> Vec<String> {
    let mut schemes = Vec::new();

    if let Some(url_types) = info_dict.get("CFBundleURLTypes").and_then(|v| v.as_array()) {
        for url_type in url_types {
            if let Some(type_dict) = url_type.as_dictionary() {
                if let Some(scheme_array) = type_dict
                    .get("CFBundleURLSchemes")
                    .and_then(|v| v.as_array())
                {
                    for scheme_value in scheme_array {
                        if let Some(scheme) = scheme_value.as_string() {
                            schemes.push(scheme.to_string());
                        }
                    }
                }
            }
        }
    }

    schemes
}
