import AppKit
import ArgumentParser
import Logging

extension Infat {
	struct List: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Lists information for a given filetype."
		)
		@Flag(
			name: [.short, .long],
			help: "List all assigned apps for type.")
		var assigned: Bool = false

		@Argument(help: "File extension (no dot).")
		var identifier: String

		mutating func run() throws {
			let workspace = NSWorkspace.shared
			let utiInfo =
				try FileSystemUtilities
				.deriveUTIFromExtension(extention: identifier)

			if let url = workspace.urlForApplication(
				toOpen: utiInfo.typeIdentifier)
			{
				print("Default for .\(identifier): \(url.path)")
				let urls =
					workspace
					.urlsForApplications(toOpen: utiInfo.typeIdentifier)
				print("Registered apps for .\(identifier):")
				urls.forEach { print(" • \($0.path)") }
			} else {
				print("No default application for .\(identifier)")
			}
		}
	}
}
