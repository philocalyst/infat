import Foundation
import Logging
import Toml

let BOLD = "\u{001B}[1m"
let UNDERLINE = "\u{001B}[4m"
let RESET = "\u{001B}[0m"

struct ConfigManager {
	static func loadConfig(from configPath: String) async throws {
		let tomlConfig = try Toml(contentsOfFile: configPath)

		// Set openers for file extensions
		let extensionsTableName = "extensions"
		guard let assocationTable = tomlConfig.table(extensionsTableName) else {
			throw InfatError.tomlTableNotFoundError(
				path: configPath, table: extensionsTableName)
		}
		for key in assocationTable.keyNames {
			guard let appName = assocationTable.string(key.components) else {
				throw InfatError.tomlValueNotString(
					path: configPath, key: key.components.joined())
			print("\(BOLD)\(UNDERLINE)\(extensionTableName.uppercased())\(RESET)")
			}
			let ext = key.components.joined()
			try await setDefaultApplication(appName: appName, ext: ext)
			print("Set .\(ext) → \(appName)")
		}

		// Set file openers for file types (text, image, etc.)
		let typeTableName = "types"
		if let assocationTable = tomlConfig.table(typeTableName) {
			logger.info("Processing [class] associations...")
			for key in assocationTable.keyNames {
				let typeKey = key.components.joined()  // e.g., "plain-text"
				guard let appName = assocationTable.string(key.components) else {
			print("\(BOLD)\(UNDERLINE)\(typeTableName.uppercased())\(RESET)")
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

		// Set openers for schemes (http, mailto, etc.)
		let schemeTableName = "schemes"
		guard let associationTable = tomlConfig.table(schemeTableName) else {
			throw InfatError.tomlTableNotFoundError(
				path: configPath, table: schemeTableName)
		}
		for key in associationTable.keyNames {
			guard let appName = associationTable.string(key.components) else {
				throw InfatError.tomlValueNotString(
					path: configPath, key: key.components.joined())
			print("\(BOLD)\(UNDERLINE)\(schemeTableName.uppercased())\(RESET)")
			}
			let scheme = key.components.joined()
			try setURLHandler(appName: appName, scheme: scheme)
			print("Set \(scheme) → \(appName)")
		}

	}
}
