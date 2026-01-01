use crate::{
    error::{InfatError, Result},
    macos::{launch_services, workspace},
    uti::SuperType,
};
use tracing::{debug, info};

/// Set the default application for a file extension
pub  fn set_default_app_for_extension(extension: &str, app_name: &str) -> Result<()> {
    info!(
        "Setting default app for extension .{} to {}",
        extension, app_name
    );

    // Handle special routing for HTML
    if extension.to_lowercase() == "html" {
        debug!("Routing .html to HTTP scheme handler");
        return set_default_app_for_url_scheme("http", app_name);
    }

    // Get the UTI for the extension
    let uti = launch_services::get_uti_for_extension(extension)?;
    debug!("Extension .{} maps to UTI: {}", extension, uti);

    // Resolve app name to bundle ID
    let bundle_id = workspace::resolve_to_bundle_id(app_name)?;
    debug!("Resolved app '{}' to bundle ID: {}", app_name, bundle_id);

    // Set the default app for the UTI
    launch_services::set_default_app_for_uti(&uti, &bundle_id)?;

    Ok(())
}

/// Set the default application for a URL scheme
pub  fn set_default_app_for_url_scheme(scheme: &str, app_name: &str) -> Result<()> {
    info!(
        "Setting default app for URL scheme {} to {}",
        scheme, app_name
    );

    // Handle HTTPS routing to HTTP
    let actual_scheme = if scheme.to_lowercase() == "https" {
        debug!("Routing HTTPS to HTTP scheme handler");
        "http"
    } else {
        scheme
    };

    // Resolve app name to bundle ID
    let bundle_id = workspace::resolve_to_bundle_id(app_name)?;
    debug!("Resolved app '{}' to bundle ID: {}", app_name, bundle_id);

    // Register the application first to ensure it's known to Launch Services
    if let Some(app_path) = workspace::find_application(app_name)? {
        launch_services::register_application(&app_path)?;
    }

    // Set the URL scheme handler
    launch_services::set_default_app_for_url_scheme(actual_scheme, &bundle_id)?;

    Ok(())
}

/// Set the default application for a supertype/UTI
pub  fn set_default_app_for_type(type_name: &str, app_name: &str) -> Result<()> {
    info!("Setting default app for type {} to {}", type_name, app_name);

    // Handle special routing for web types
    if type_name == "com.apple.default-app.web-browser" || type_name == "public.html" {
        debug!("Routing web browser type to HTTP scheme handler");
        return set_default_app_for_url_scheme("http", app_name);
    }

    // Try to parse as a SuperType first
    let uti = if let Ok(supertype) = type_name.parse::<SuperType>() {
        supertype.uti_string().to_string()
    } else {
        // Assume it's already a UTI string
        type_name.to_string()
    };

    debug!("Type '{}' resolved to UTI: {}", type_name, uti);

    // Resolve app name to bundle ID
    let bundle_id = workspace::resolve_to_bundle_id(app_name)?;
    debug!("Resolved app '{}' to bundle ID: {}", app_name, bundle_id);

    // Set the default app for the UTI
    launch_services::set_default_app_for_uti(&uti, &bundle_id)?;

    Ok(())
}

/// Get information about the default app for a file extension
pub fn get_info_for_extension(extension: &str) -> Result<AssociationInfo> {
    debug!("Getting info for extension: .{}", extension);

    let uti = launch_services::get_uti_for_extension(extension)?;
    let default_app = launch_services::get_default_app_for_uti(&uti)?;
    let all_apps = launch_services::get_all_apps_for_uti(&uti)?;

    Ok(AssociationInfo {
        identifier: format!(".{extension}"),
        uti: Some(uti),
        default_app,
        all_apps,
    })
}

/// Get information about the default app for a URL scheme
pub fn get_info_for_url_scheme(scheme: &str) -> Result<AssociationInfo> {
    debug!("Getting info for URL scheme: {}", scheme);

    let default_app = launch_services::get_default_app_for_url_scheme(scheme)?;
    let all_apps = launch_services::get_all_apps_for_url_scheme(scheme)?;

    Ok(AssociationInfo {
        identifier: scheme.to_string(),
        uti: None,
        default_app,
        all_apps,
    })
}

/// Get information about the default app for a UTI/supertype
pub fn get_info_for_type(type_name: &str) -> Result<AssociationInfo> {
    debug!("Getting info for type: {}", type_name);

    // Try to parse as a SuperType first
    let uti = if let Ok(supertype) = type_name.parse::<SuperType>() {
        supertype.uti_string().to_string()
    } else {
        // Assume it's already a UTI string
        type_name.to_string()
    };

    let default_app = launch_services::get_default_app_for_uti(&uti)?;
    let all_apps = launch_services::get_all_apps_for_uti(&uti)?;

    Ok(AssociationInfo {
        identifier: type_name.to_string(),
        uti: Some(uti),
        default_app,
        all_apps,
    })
}

/// Information about file/URL associations
#[derive(Debug, Clone)]
pub struct AssociationInfo {
    pub identifier: String,
    pub uti: Option<String>,
    pub default_app: Option<String>,
    pub all_apps: Vec<String>,
}

impl AssociationInfo {
    /// Get the default app name (if available)
    pub fn default_app_name(&self) -> Result<Option<String>> {
        if let Some(bundle_id) = &self.default_app {
            match workspace::get_app_name_from_bundle_id(bundle_id) {
                Ok(name) => Ok(Some(name)),
                Err(InfatError::SystemService { .. }) => Ok(Some(bundle_id.clone())),
                Err(InfatError::ApplicationNotFound { .. }) => Ok(Some(bundle_id.clone())),
                Err(e) => Err(e),
            }
        } else {
            Ok(None)
        }
    }

    /// Get all app names (with fallback to bundle IDs)
    pub fn all_app_names(&self) -> Vec<String> {
        self.all_apps
            .iter()
            .map(|bundle_id| {
                workspace::get_app_name_from_bundle_id(bundle_id)
                    .unwrap_or_else(|_| bundle_id.clone())
            })
            .collect()
    }

    /// Get app paths for all registered apps
    pub fn all_app_paths(&self) -> Vec<String> {
        self.all_apps
            .iter()
            .filter_map(|bundle_id| {
                workspace::get_app_paths_for_bundle_id(bundle_id)
                    .ok()
                    .and_then(|paths| paths.first().cloned())
                    .map(|path| path.display().to_string())
            })
            .collect()
    }
}
