import ArgumentParser
import Logging

extension Infat {
	struct Bind: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Sets a URL scheme association."
		)
		@Argument(help: "The name of the application.")
		var appName: String

		@Argument(help: "The file extension (no dot).")
		var scheme: String

		mutating func run() throws {
			let apps = try FileSystemUtilities.findApplications()
			let applicationURL = findApplication(applications: apps, key: appName)
			if let appURL = applicationURL {
				try setURLHandler(scheme: scheme, appURL: appURL)
			} else {
				throw InfatError.applicationNotFound(name: appName)
			}
		}
	}
}
