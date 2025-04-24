import Foundation

enum InfatError: Error, LocalizedError {
	case cannotDetermineUTI
	case cannotSetURL(appName: String)
	case cannotRegisterURL(error: Int32)
	case unsupportedOSVersion
	case directoryReadError(path: String, underlyingError: Error)
	case pathExpansionError(path: String)
	case applicationNotFound(name: String)
	case plistReadError(path: String, underlyingError: Error)
	case defaultAppSettingError(underlyingError: Error)
	case noActiveApplication
	case configurationLoadError(path: String, underlyingError: Error)
	case operationTimeout
	case tomlLoadError(path: String, underlyingError: Error)
	case tomlTableNotFoundError(path: String, table: String)
	case tomlValueNotString(path: String, key: String)

	var errorDescription: String? {
		switch self {
		case .cannotDetermineUTI:
			return "Cannot determine UTI for the specified file"
		case .cannotRegisterURL(let error):
			return "Cannot register provided URL, got error \(error)"
		case .cannotSetURL(let app):
			return "Cannot set scheme for app \(app)"
		case .unsupportedOSVersion:
			return "This functionality requires a later version of macOS"
		case .directoryReadError(let path, let error):
			return "Error reading directory at \(path): \(error.localizedDescription)"
		case .pathExpansionError(let path):
			return "Could not expand path: \(path)"
		case .applicationNotFound(let name):
			return "Application not found: \(name)"
		case .plistReadError(let path, let error):
			return "Error reading or parsing Info.plist at \(path): \(error.localizedDescription)"
		case .defaultAppSettingError(let error):
			return "Failed to set default application: \(error.localizedDescription)"
		case .noActiveApplication:
			return "No active application found"
		case .configurationLoadError(let path, let error):
			return "Failed to load configuration from \(path): \(error.localizedDescription)"
		case .operationTimeout:
			return "Operation timed out"
		case .tomlLoadError(let path, let error):
			return "Failed to load TOML from \(path): \(error.localizedDescription)"
		case .tomlTableNotFoundError(let path, let table):
			return "Table '\(table)' not found in TOML file \(path)"
		case .tomlValueNotString(let path, let key):
			return "Value for key '\(key)' in TOML file \(path) is not a string."
		}
	}
}
