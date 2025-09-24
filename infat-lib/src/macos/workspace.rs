// infat-lib/src/macos/workspace.rs
//! NSWorkspace integration for app discovery and management

use crate::error::{InfatError, Result};
use objc::{class, msg_send, runtime::Object, sel, sel_impl};
use objc_foundation::{INSString, NSString};
use std::path::{Path, PathBuf};
use tracing::debug;

#[link(name = "AppKit", kind = "framework")]
extern "C" {}

/// Get the shared NSWorkspace instance
unsafe fn shared_workspace() -> *mut Object {
    let workspace_class = class!(NSWorkspace);
    msg_send![workspace_class, sharedWorkspace]
}

/// Find application paths for a bundle identifier
pub fn get_app_paths_for_bundle_id(bundle_id: &str) -> Result<Vec<PathBuf>> {
    debug!("Finding app paths for bundle ID: {}", bundle_id);

    unsafe {
        let workspace = shared_workspace();
        let ns_bundle_id = NSString::from_str(bundle_id);
        let cf_url: *mut Object =
            msg_send![workspace, URLForApplicationWithBundleIdentifier: ns_bundle_id];

        if cf_url.is_null() {
            debug!("No application found for bundle ID: {}", bundle_id);
            return Ok(Vec::new());
        }

        let ns_path: *mut NSString = msg_send![cf_url, path];
        let path_str = (*ns_path).as_str();
        let path = PathBuf::from(path_str);

        debug!("Found app path for {}: {}", bundle_id, path.display());
        Ok(vec![path])
    }
}

/// Get bundle identifier from application path
pub fn get_bundle_id_from_app_path<P: AsRef<Path>>(app_path: P) -> Result<String> {
    let path = app_path.as_ref();
    debug!("Getting bundle ID for app: {}", path.display());

    // Read Info.plist from the app bundle
    let info_plist_path = path.join("Contents").join("Info.plist");

    if !info_plist_path.exists() {
        return Err(InfatError::InfoPlistNotFound {
            app_path: path.to_path_buf(),
        });
    }

    let plist_data = std::fs::read(&info_plist_path)?;
    let plist: plist::Value =
        plist::from_bytes(&plist_data).map_err(|e| InfatError::PlistReadError {
            path: info_plist_path.clone(),
            source: Box::new(e),
        })?;

    let bundle_id = plist
        .as_dictionary()
        .and_then(|dict| dict.get("CFBundleIdentifier"))
        .and_then(|val| val.as_string())
        .ok_or_else(|| InfatError::BundleIdNotFound {
            path: path.to_path_buf(),
        })?;

    debug!("Bundle ID for {}: {}", path.display(), bundle_id);
    Ok(bundle_id.to_string())
}

/// Get app name (display name) from bundle ID
pub fn get_app_name_from_bundle_id(bundle_id: &str) -> Result<String> {
    debug!("Getting app name for bundle ID: {}", bundle_id);

    // Check for system services
    if is_system_service(bundle_id) {
        return Err(InfatError::SystemService {
            bundle: bundle_id.to_string(),
        });
    }

    let app_paths = get_app_paths_for_bundle_id(bundle_id)?;

    let app_path = app_paths
        .first()
        .ok_or_else(|| InfatError::ApplicationNotFound {
            name: bundle_id.to_string(),
        })?;

    // Read display name from Info.plist
    let info_plist_path = app_path.join("Contents").join("Info.plist");
    let plist_data = std::fs::read(&info_plist_path)?;
    let plist: plist::Value =
        plist::from_bytes(&plist_data).map_err(|e| InfatError::PlistReadError {
            path: info_plist_path.clone(),
            source: Box::new(e),
        })?;

    let dict = plist
        .as_dictionary()
        .ok_or_else(|| InfatError::PlistReadError {
            path: info_plist_path.clone(),
            source: "Info.plist root is not a dictionary".into(),
        })?;

    // Try CFBundleDisplayName first, then CFBundleName
    let app_name = dict
        .get("CFBundleDisplayName")
        .or_else(|| dict.get("CFBundleName"))
        .and_then(|val| val.as_string())
        .unwrap_or("Unknown");

    let authoritive_id = dict
        .get("CFBundleIdentifier")
        .expect("Required for any registered app")
        .as_string()
        .unwrap_or("Unknown");

    // Prioritize the pretty name but fallbak on the authoritive
    if app_name != authoritive_id {
        return Ok(app_name.to_string());
    }

    debug!("App name for {}: {}", bundle_id, app_name);
    Ok(app_name.to_string())
}

/// Find applications in standard directories
pub fn find_applications() -> Result<Vec<PathBuf>> {
    debug!("Searching for applications in standard directories");

    let search_paths = [
        "/Applications",
        "/System/Applications",
        "/System/Library/CoreServices/Applications",
        &format!("{}/Applications", std::env::var("HOME").unwrap_or_default()),
    ];

    let mut apps = Vec::new();

    for search_path in &search_paths {
        let path = Path::new(search_path);
        if !path.exists() {
            debug!("Skipping non-existent path: {}", search_path);
            continue;
        }

        match std::fs::read_dir(path) {
            Ok(entries) => {
                let mut found_count = 0;
                for entry in entries.flatten() {
                    let entry_path = entry.path();
                    if entry_path.extension().is_some_and(|ext| ext == "app") {
                        apps.push(entry_path);
                        found_count += 1;
                    }
                }
                debug!("Found {} apps in {}", found_count, search_path);
            }
            Err(e) => {
                debug!("Could not read directory {}: {}", search_path, e);
            }
        }
    }

    debug!("Total applications found: {}", apps.len());
    Ok(apps)
}

/// Find application by name or bundle ID
pub fn find_application(name_or_bundle_id: &str) -> Result<Option<PathBuf>> {
    debug!("Finding application: {}", name_or_bundle_id);

    // If it looks like a bundle ID, try that first
    if name_or_bundle_id.contains('.') {
        if let Ok(paths) = get_app_paths_for_bundle_id(name_or_bundle_id) {
            if let Some(path) = paths.first() {
                return Ok(Some(path.clone()));
            }
        }
    }

    // Try as a file path
    let path = PathBuf::from(name_or_bundle_id);
    if path.exists() && path.extension().is_some_and(|ext| ext == "app") {
        return Ok(Some(path));
    }

    // Search by name in standard directories
    let apps = find_applications()?;
    for app_path in apps {
        let app_name = app_path
            .file_stem()
            .and_then(|stem| stem.to_str())
            .unwrap_or("");

        if app_name.eq_ignore_ascii_case(name_or_bundle_id) {
            return Ok(Some(app_path));
        }
    }

    debug!("Application not found: {}", name_or_bundle_id);
    Ok(None)
}

/// Check if a bundle ID represents a system service
pub fn is_system_service(bundle_id: &str) -> bool {
    bundle_id.starts_with("com.apple.")
        && (bundle_id.contains("service")
            || bundle_id.contains("ui")
            || bundle_id.contains("daemon"))
}

/// Resolve app name or bundle ID to a bundle ID
pub fn resolve_to_bundle_id(name_or_bundle_id: &str) -> Result<String> {
    debug!("Resolving to bundle ID: {}", name_or_bundle_id);

    // Find the application and get its bundle ID
    let app_path =
        find_application(name_or_bundle_id)?.ok_or_else(|| InfatError::ApplicationNotFound {
            name: name_or_bundle_id.to_string(),
        })?;

    get_bundle_id_from_app_path(app_path)
}
