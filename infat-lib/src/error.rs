use std::path::PathBuf;
use thiserror::Error;

pub type Result<T> = std::result::Result<T, InfatError>;

#[derive(Error, Debug)]
pub enum InfatError {
    #[error("Could not derive UTI for extension '.{extension}'")]
    CouldNotDeriveUTI { extension: String },

    #[error("System service '{bundle}' cannot be used as default application")]
    SystemService { bundle: String },

    #[error("Missing required option")]
    MissingOption,

    #[error("No valid configuration tables found in '{path}'")]
    NoConfigTables { path: PathBuf },

    #[error("Info.plist not found in application bundle: {app_path}")]
    InfoPlistNotFound { app_path: PathBuf },

    #[error("Unsupported or invalid supertype: {name}")]
    UnsupportedSupertype { name: String },

    #[error("Cannot set URL scheme for application '{app_name}'")]
    CannotSetURL { app_name: String },

    #[error("Cannot register URL, Launch Services error: {error_code}")]
    CannotRegisterURL { error_code: i32 },

    #[error("macOS version not supported for this operation")]
    UnsupportedOSVersion,

    #[error("Supertype missing for intended type: {intended_type}")]
    SupertypeMissing { intended_type: String },

    #[error("Conflicting options: {message}")]
    ConflictingOptions { message: String },

    #[error("Error reading directory '{path}'")]
    DirectoryReadError {
        path: PathBuf,
        #[source]
        source: std::io::Error,
    },

    #[error("Could not expand path: {path}")]
    PathExpansionError { path: PathBuf },

    #[error("Application not found: {name}")]
    ApplicationNotFound { name: String },

    #[error("Could not get bundle identifier from path: {path}")]
    BundleIdNotFound { path: PathBuf },

    #[error("Error reading Info.plist at '{path}'")]
    PlistReadError {
        path: PathBuf,
        #[source]
        source: Box<dyn std::error::Error + Send + Sync>,
    },

    #[error("Failed to set default application")]
    DefaultAppSettingError {
        #[source]
        source: Box<dyn std::error::Error + Send + Sync>,
    },

    #[error("No active application found")]
    NoActiveApplication,

    #[error("Failed to load configuration from '{path}'")]
    ConfigurationLoadError {
        path: PathBuf,
        #[source]
        source: Box<dyn std::error::Error + Send + Sync>,
    },

    #[error("Operation timed out")]
    OperationTimeout,

    #[error("TOML value for key '{key}' is not a string")]
    TomlValueNotString { key: String },

    #[error("Invalid bundle '{bundle}' for application '{app}'")]
    InvalidBundle { bundle: String, app: String },

    #[error("Launch Services API error: {message}")]
    LaunchServicesError { message: String },

    #[error("Core Foundation error: {message}")]
    CoreFoundationError { message: String },

    #[error("Generic error: {message}")]
    Generic { message: String },

    #[error("IO error")]
    Io(#[from] std::io::Error),

    #[error("TOML parsing error")]
    TomlParse(#[from] toml::de::Error),

    #[error("TOML serialization error")]
    TomlSerialize(#[from] toml::ser::Error),
}

// Add From<eyre::Report> for InfatError
impl From<eyre::Report> for InfatError {
    fn from(report: eyre::Report) -> Self {
        InfatError::Generic {
            message: report.to_string(),
        }
    }
}

// Helper trait for adding context to our custom errors
pub trait InfatErrorExt<T> {
    fn app_not_found(self, name: impl Into<String>) -> Result<T>;
    fn config_load_error(self, path: impl Into<PathBuf>) -> Result<T>;
    fn plist_read_error(self, path: impl Into<PathBuf>) -> Result<T>;
}

impl<T, E> InfatErrorExt<T> for std::result::Result<T, E>
where
    E: std::error::Error + Send + Sync + 'static,
{
    fn app_not_found(self, name: impl Into<String>) -> Result<T> {
        self.map_err(|_| InfatError::ApplicationNotFound { name: name.into() })
    }

    fn config_load_error(self, path: impl Into<PathBuf>) -> Result<T> {
        self.map_err(|e| InfatError::ConfigurationLoadError {
            path: path.into(),
            source: Box::new(e),
        })
    }

    fn plist_read_error(self, path: impl Into<PathBuf>) -> Result<T> {
        self.map_err(|e| InfatError::PlistReadError {
            path: path.into(),
            source: Box::new(e),
        })
    }
}
