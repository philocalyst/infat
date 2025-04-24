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
			try setURLHandler(appName: appName, scheme: scheme)
			print("Successfully bound \(appName) to \(scheme)")

		}
	}
}
