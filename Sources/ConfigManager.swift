import Foundation
import Logging
import Toml

struct ConfigManager {
	static func loadConfig(from configPath: String) async throws {
		let tomlConfig = try Toml(contentsOfFile: configPath)

		// Set openers for file types
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
			try await setDefaultApplication(appName: appName, fileType: ext)
			print("Set .\(ext) → \(appName)")
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
