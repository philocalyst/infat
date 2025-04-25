import Foundation
import Logging
import Toml

struct ConfigManager {
	static func loadConfig(from configPath: String) async throws {
		let tomlConfig = try Toml(contentsOfFile: configPath)

		// Set openers for file extensions
		guard let associationsTable = tomlConfig.table("files") else {
			throw InfatError.tomlTableNotFoundError(
				path: configPath, table: "files")
		}
		for key in associationsTable.keyNames {
			guard let appName = associationsTable.string(key.components) else {
				throw InfatError.tomlValueNotString(
					path: configPath, key: key.components.joined())
			}
			let ext = key.components.joined()
			try await setDefaultApplication(appName: appName, ext: ext)
			print("Set .\(ext) → \(appName)")
		}

		// Set file openers for classes
		if let classTable = tomlConfig.table("class") {
			logger.info("Processing [class] associations...")
			for key in classTable.keyNames {
				let typeKey = key.components.joined()  // e.g., "plain-text"
				guard let appName = classTable.string(key.components) else {
					logger.warning(
						"Value for key '\(typeKey)' in [class] is not a string. Skipping.")
					continue
				}

				// Validate the key
				guard let wellKnownType = Supertypes(rawValue: typeKey) else {
					logger.error("Invalid type key '\(typeKey)' found in [class] table. Skipping.")
					continue
				}

				// Get the actual UTType
				guard let targetUTType = wellKnownType.utType else {
					logger.error(
						"Well-known type '\(typeKey)' is not supported on this OS version or invalid. Skipping."
					)
					throw InfatError.unsupportedOrInvalidSupertype(name: typeKey)
				}

				logger.debug(
					"Config: Queueing set default for type \(typeKey) (\(targetUTType.identifier)) to \(appName)"
				)
				try await setDefaultApplication(appName: appName, supertype: targetUTType)
				print("Set type \(typeKey) → \(appName)")
			}
		} else {
			logger.debug("No [class] table found in \(configPath)")
		}

		// Set openers for schemes
		guard let associationsTable = tomlConfig.table("schemes") else {
			throw InfatError.tomlTableNotFoundError(
				path: configPath, table: "schemes")
		}
		for key in associationsTable.keyNames {
			guard let appName = associationsTable.string(key.components) else {
				throw InfatError.tomlValueNotString(
					path: configPath, key: key.components.joined())
			}
			let scheme = key.components.joined()
			try setURLHandler(appName: appName, scheme: scheme)
			print("Set \(scheme) → \(appName)")
		}

	}
}
