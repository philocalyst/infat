import ColorizeSwift
import Foundation
import Logging
import Toml

struct ConfigManager {
	static func loadConfig(from configPath: String) async throws {
		let tomlConfig = try Toml(contentsOfFile: configPath)

		// Convenience names
		let extensionTableName = "extensions"
		let schemeTableName = "schemes"
		let typeTableName = "types"

		// Check upfront that at least one table is present
		let hasExtensions = tomlConfig.table(extensionTableName) != nil
		let hasSchemes = tomlConfig.table(schemeTableName) != nil
		let hasTypes = tomlConfig.table(typeTableName) != nil

		guard hasExtensions || hasSchemes || hasTypes else {
			throw InfatError.noConfigTables(path: configPath)
		}

		// MARK: – Process [extensions]
		if let extensionTable = tomlConfig.table(extensionTableName) {
			logger.info("Processing [extensions] associations...")
			print("\(extensionTableName.uppercased().bold().underline())")
			for key in extensionTable.keyNames {
				guard let appName = extensionTable.string(key.components) else {
					throw InfatError.tomlValueNotString(
						path: configPath,
						key: key.components.joined()
					)
				}
				let ext = key.components.joined()
				switch ext.lowercased() {
				case "html":
					// Route .html to the http URL handler
					try setURLHandler(appName: appName, scheme: "http")
					print("Set .\(ext) → \(appName) (routed to http)")
				default:
					try await setDefaultApplication(appName: appName, ext: ext)
					print("Set .\(ext) → \(appName)")
				}
			}
		} else {
			logger.debug("No [extensions] table found in \(configPath)")
		}

		// MARK: – Process [types]
		if let typeTable = tomlConfig.table(typeTableName) {
			logger.info("Processing [types] associations...")
			print("\(typeTableName.uppercased().bold().underline())")
			for key in typeTable.keyNames {
				let typeKey = key.components.joined()
				guard let appName = typeTable.string(key.components) else {
					logger.warning(
						"Value for key '\(typeKey)' in [types] is not a string. Skipping."
					)
					continue
				}
				guard let supertypeEnum = Supertypes(rawValue: typeKey) else {
					logger.error(
						"Invalid type key '\(typeKey)' found in [types]. Skipping."
					)
					continue
				}
				guard let targetUTType = supertypeEnum.utType else {
					logger.error(
						"Well-known type '\(typeKey)' not supported or invalid. Skipping."
					)
					throw InfatError.unsupportedOrInvalidSupertype(name: typeKey)
				}

				logger.debug(
					"Queueing default app for type \(typeKey) (\(targetUTType.identifier)) → \(appName)"
				)
				try await setDefaultApplication(
					appName: appName,
					supertype: targetUTType
				)
				print("Set type \(typeKey) → \(appName)")
			}
		} else {
			logger.debug("No [types] table found in \(configPath)")
		}

		// MARK: – Process [schemes]
		if let schemeTable = tomlConfig.table(schemeTableName) {
			logger.info("Processing [schemes] associations...")
			print("\(schemeTableName.uppercased().bold().underline())")
			for key in schemeTable.keyNames {
				guard let appName = schemeTable.string(key.components) else {
					throw InfatError.tomlValueNotString(
						path: configPath,
						key: key.components.joined()
					)
				}
				let scheme = key.components.joined()
				switch scheme.lowercased() {
				case "https":
					// Route https to the http URL handler
					try setURLHandler(appName: appName, scheme: "http")
					print("Set https → \(appName) (routed to http)")
				default:
					try setURLHandler(appName: appName, scheme: scheme)
					print("Set \(scheme) → \(appName)")
				}
			}
		} else {
			logger.debug("No [schemes] table found in \(configPath)")
		}
	}
}
