import AppKit
import ArgumentParser
import Foundation
import Logging

var logger = Logger(label: "com.example.workspacetool")

@main
struct WorkspaceTool: ParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "A tool to interact with NSWorkspace.",
		version: "0.1.0",
		subcommands: [List.self, SetCommand.self, Info.self]
	)

	@Option(name: [.short, .long], help: "Path to the configuration file.")
	var config: String?

	@Flag(name: [.short, .long], help: "Show the version of the tool.")
	var version: Bool = false

	mutating func run() throws {
		if version {
			print("WorkspaceTool version \(WorkspaceTool.configuration.version ?? "unknown")")
			return
		}

		if let configPath = config {
			logger.info("Using configuration file: \(configPath)")
			// TODO: Config loading
		}
	}
}

extension WorkspaceTool {
	struct List: ParsableCommand {
		static let configuration = CommandConfiguration(abstract: "Lists something (example).")

		@Flag(name: [.short, .long], help: "List all items.")
		var all: Bool = false

		@Argument(help: "Close search to a specific identifier")
		var identifier: String? = nil

		mutating func run() throws {
			logger.info("Executing 'list' subcommand")
			let workspace = NSWorkspace.shared

			if all {
				logger.info("Listing all items...")
				// TODO: Config listing non-relevant entries
			} else {
				logger.info("Listing some items...")
				// TODO: Config listing minute details
			}
		}
	}
}

extension WorkspaceTool {
	struct SetCommand: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Sets an application association.")

		@Argument(help: "The name of the application.")
		var appName: String

		@Argument(help: "The MIME type to associate.")
		var mimeType: String

		@Argument(help: "The role for the association.")
		var role: String

		mutating func run() throws {
			logger.info("Executing 'set' subcommand")
			logger.info(
				"Setting association: App='\(appName)', MIME Type='\(mimeType)', Role='\(role)'")
		}
	}
}

extension WorkspaceTool {
	struct Info: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Displays system information (example).")

		mutating func run() throws {
			logger.info("Executing 'info' subcommand")
			let workspace = NSWorkspace.shared
			logger.info(
				"Active application name: \(workspace.frontmostApplication?.localizedName ?? "None")"
			)
		}
	}
}
