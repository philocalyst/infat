import Foundation
import Logging
import Toml

struct ConfigManager {
	static func loadConfig(from configPath: String) throws {
		let toml = try Toml(contentsOfFile: configPath)
		guard let table = toml.table("associations") else {
			throw InfatError.tomlTableNotFoundError(
				path: configPath, table: "associations")
		}
		for key in table.keyNames {
			guard let appName = table.string(key.components) else {
				throw InfatError.tomlValueNotString(
					path: configPath, key: key.components.joined())
			}
			let ext = key.components.joined()
			try setDefaultApplication(appName: appName, fileType: ext)
			print("Set .\(ext) → \(appName)")
		}
	}
}
