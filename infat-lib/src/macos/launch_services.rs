// infat-lib/src/macos/launch_services.rs
//! High-level Launch Services API wrappers

use super::ffi::*;
use crate::error::{InfatError, Result};
use core_foundation::{
    array::CFArray,
    base::TCFType,
    string::CFString,
    url::CFURL,
};
use std::path::Path;
use tracing::debug;

/// Set the default application for a URL scheme
pub fn set_default_app_for_url_scheme(scheme: &str, bundle_id: &str) -> Result<()> {
    debug!(
        "Setting default app for scheme '{}' to '{}'",
        scheme, bundle_id
    );

    let cf_scheme = CFString::new(scheme);
    let cf_bundle_id = CFString::new(bundle_id);

    let status = unsafe {
        LSSetDefaultHandlerForURLScheme(
            cf_scheme.as_concrete_TypeRef(),
            cf_bundle_id.as_concrete_TypeRef(),
        )
    };

    if status != 0 {
        return Err(InfatError::LaunchServicesError {
            message: format!("Failed to set URL scheme handler: error {status}"),
        });
    }

    debug!("Successfully set {} → {}", scheme, bundle_id);
    Ok(())
}

/// Set the default application for a UTI
pub fn set_default_app_for_uti(uti: &str, bundle_id: &str) -> Result<()> {
    debug!("Setting default app for UTI '{}' to '{}'", uti, bundle_id);

    let cf_uti = CFString::new(uti);
    let cf_bundle_id = CFString::new(bundle_id);

    let status = unsafe {
        LSSetDefaultRoleHandlerForContentType(
            cf_uti.as_concrete_TypeRef(),
            K_LS_ROLES_VIEWER,
            cf_bundle_id.as_concrete_TypeRef(),
        )
    };

    if status != 0 {
        return Err(InfatError::LaunchServicesError {
            message: format!("Failed to set UTI handler: error {status}"),
        });
    }

    debug!("Successfully set UTI {} → {}", uti, bundle_id);
    Ok(())
}

/// Get the default application bundle ID for a URL scheme
pub fn get_default_app_for_url_scheme(scheme: &str) -> Result<Option<String>> {
    debug!("Getting default app for URL scheme: {}", scheme);

    let cf_scheme = CFString::new(scheme);
    let cf_bundle_id = unsafe { LSCopyDefaultHandlerForURLScheme(cf_scheme.as_concrete_TypeRef()) };

    if cf_bundle_id.is_null() {
        return Ok(None);
    }

    let bundle_id = unsafe { CFString::wrap_under_create_rule(cf_bundle_id) }.to_string();
    debug!("Default app for scheme '{}': {}", scheme, bundle_id);
    Ok(Some(bundle_id))
}

/// Get the default application bundle ID for a UTI
pub fn get_default_app_for_uti(uti: &str) -> Result<Option<String>> {
    debug!("Getting default app for UTI: {}", uti);

    let cf_uti = CFString::new(uti);
    let cf_bundle_id = unsafe {
        LSCopyDefaultRoleHandlerForContentType(cf_uti.as_concrete_TypeRef(), K_LS_ROLES_VIEWER)
    };

    if cf_bundle_id.is_null() {
        return Ok(None);
    }

    let bundle_id = unsafe { CFString::wrap_under_create_rule(cf_bundle_id) }.to_string();
    debug!("Default app for UTI '{}': {}", uti, bundle_id);
    Ok(Some(bundle_id))
}

/// Get all applications that can handle a URL scheme
pub fn get_all_apps_for_url_scheme(scheme: &str) -> Result<Vec<String>> {
    debug!("Getting all apps for URL scheme: {}", scheme);

    let cf_scheme = CFString::new(scheme);
    let cf_array = unsafe { LSCopyAllHandlersForURLScheme(cf_scheme.as_concrete_TypeRef()) };

    if cf_array.is_null() {
        return Ok(Vec::new());
    }

    let array = unsafe { CFArray::<CFString>::wrap_under_create_rule(cf_array) };
    let mut result = Vec::new();

    for i in 0..array.len() {
        if let Some(cf_string) = array.get(i) {
            result.push(cf_string.to_string());
        }
    }

    debug!("Found {} apps for scheme '{}'", result.len(), scheme);
    Ok(result)
}

/// Get all applications that can handle a UTI
pub fn get_all_apps_for_uti(uti: &str) -> Result<Vec<String>> {
    debug!("Getting all apps for UTI: {}", uti);

    let cf_uti = CFString::new(uti);
    let cf_array = unsafe {
        LSCopyAllRoleHandlersForContentType(cf_uti.as_concrete_TypeRef(), K_LS_ROLES_VIEWER)
    };

    if cf_array.is_null() {
        return Ok(Vec::new());
    }

    let array = unsafe { CFArray::<CFString>::wrap_under_create_rule(cf_array) };
    let mut result = Vec::new();

    for i in 0..array.len() {
        if let Some(cf_string) = array.get(i) {
            result.push(cf_string.to_string());
        }
    }

    debug!("Found {} apps for UTI '{}'", result.len(), uti);
    Ok(result)
}

/// Register an application bundle with Launch Services
pub fn register_application<P: AsRef<Path>>(app_path: P) -> Result<()> {
    let path = app_path.as_ref();
    debug!("Registering application: {}", path.display());

    let cf_url = CFURL::from_path(path, true).ok_or_else(|| InfatError::PathExpansionError {
        path: path.to_path_buf(),
    })?;

    let status = unsafe { LSRegisterURL(cf_url.as_concrete_TypeRef(), true) };

    if status != 0 {
        return Err(InfatError::LaunchServicesError {
            message: format!("Failed to register application: error {status}"),
        });
    }

    debug!("Successfully registered application: {}", path.display());
    Ok(())
}

/// Get the UTI for a file extension
pub fn get_uti_for_extension(extension: &str) -> Result<String> {
    debug!("Getting UTI for extension: {}", extension);

    let cf_tag_class = CFString::new(K_UT_TAG_CLASS_FILENAME_EXTENSION);
    let cf_extension = CFString::new(extension);
    let cf_conforming_to = CFString::new("");

    let cf_uti = unsafe {
        UTTypeCreatePreferredIdentifierForTag(
            cf_tag_class.as_concrete_TypeRef(),
            cf_extension.as_concrete_TypeRef(),
            cf_conforming_to.as_concrete_TypeRef(),
        )
    };

    if cf_uti.is_null() {
        return Err(InfatError::CouldNotDeriveUTI {
            extension: extension.to_string(),
        });
    }

    let uti = unsafe { CFString::wrap_under_create_rule(cf_uti) }.to_string();
    debug!("UTI for extension '{}': {}", extension, uti);
    Ok(uti)
}

/// Get the preferred file extension for a UTI
pub fn get_extension_for_uti(uti: &str) -> Result<Option<String>> {
    debug!("Getting extension for UTI: {}", uti);

    let cf_uti = CFString::new(uti);
    let cf_tag_class = CFString::new(K_UT_TAG_CLASS_FILENAME_EXTENSION);

    let cf_extension = unsafe {
        UTTypeCopyPreferredTagWithClass(
            cf_uti.as_concrete_TypeRef(),
            cf_tag_class.as_concrete_TypeRef(),
        )
    };

    if cf_extension.is_null() {
        return Ok(None);
    }

    let extension = unsafe { CFString::wrap_under_create_rule(cf_extension) }.to_string();
    debug!("Extension for UTI '{}': {}", uti, extension);
    Ok(Some(extension))
}
