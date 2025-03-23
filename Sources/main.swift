import AppKit
import ArgumentParser
import Foundation
import Logging
import PListKit
import Toml
import UniformTypeIdentifiers

let logger = Logger(label: "com.example.burt")

// MARK: - Error Definitions
enum InfatError: Error, LocalizedError {
	case cannotDetermineUTI
	case unsupportedOSVersion
	case directoryReadError(path: String, underlyingError: Error)
	case pathExpansionError(path: String)
	case applicationNotFound(name: String)

	var errorDescription: String? {
		switch self {
		case .cannotDetermineUTI:
			return "Cannot determine UTI for the specified file"
		case .unsupportedOSVersion:
			return "This functionality requires a later version of macOS"
		case .directoryReadError(let path, let error):
			return "Error reading directory at \(path): \(error.localizedDescription)"
		case .pathExpansionError(let path):
			return "Could not expand path: \(path)"
		case .applicationNotFound(let name):
			return "Application not found: \(name)"
		}
	}
}

struct FileUTIInfo {
	let typeIdentifier: String
	let preferredMIMEType: String?
	let localizedDescription: String?
	let isDynamic: Bool
	let conformsTo: [String]

	// Debugging Describe UTI
	var description: String {
		var output = "UTI: \(typeIdentifier)\n"
		if let mimeType = preferredMIMEType {
			output += "MIME Type: \(mimeType)\n"
		}
		if let description = localizedDescription {
			output += "Description: \(description)\n"
		}
		output += "Is Dynamic: \(isDynamic ? "Yes" : "No")\n"
		if !conformsTo.isEmpty {
			output += "Conforms To: \(conformsTo.joined(separator: ", "))\n"
		}
		return output
	}
}

// MARK: - FileSystem Utilities
struct FileSystemUtilities {
	static func findApplications(containing namePattern: String) throws -> [URL] {
		let fileManager = FileManager.default
		var allAppURLs: [URL] = []

		// Define the two application directories to search
		// User-space and Root-space
		let applicationPaths = [
			"/Applications/",
			(NSString("~/Applications/").expandingTildeInPath as String),
		]

		// Search each directory for applications
		for path in applicationPaths {
			do {
				let directoryURL = URL(fileURLWithPath: path)
				let contents = try fileManager.contentsOfDirectory(
					at: directoryURL,
					includingPropertiesForKeys: nil,
					options: [])
				allAppURLs.append(contentsOf: contents)
				logger.debug("Found \(contents.count) items in \(path)")
			} catch {
				logger.warning("Could not read directory at \(path): \(error.localizedDescription)")
				// Expected, continue
			}
		}

		if allAppURLs.isEmpty {
			logger.error("No applications found in any search directory")
		}

		return allAppURLs
	}

	static func deriveUTIFromExtension(extention: String) throws -> FileUTIInfo {
		guard #available(macOS 11.0, *) else {
			logger.error("UTI functionality requires macOS 11.0 or later")
			throw InfatError.unsupportedOSVersion
		}

		// The apple-defined UTTypes to check for conformance
		let commonUTTypes: [UTType] = [
			.content, .text, .plainText, .utf8PlainText, .utf16PlainText,
			.delimitedText, .commaSeparatedText, .tabSeparatedText,
			.rtf, .pdf, .sourceCode, .swiftSource, .objectiveCSource, .cSource, .cPlusPlusSource,
			.script, .appleScript, .javaScript, .shellScript, .pythonScript, .rubyScript,
			.image, .jpeg, .png, .tiff, .gif, .bmp, .svg, .heic,
			.movie, .video, .audio, .quickTimeMovie, .mpeg, .mpeg2Video, .mpeg4Movie, .mp3,
			.presentation, .spreadsheet, .database,
			.archive, .gzip, .zip, .diskImage, .bz2,
		]

		guard let utType = UTType(filenameExtension: extention) else {
			throw InfatError.cannotDetermineUTI
		}

		let conformsTo = commonUTTypes.filter { utType.conforms(to: $0) }.map { $0.identifier }
		logger.debug("Determined UTI \(utType.identifier) for \(extention)")

		return FileUTIInfo(
			typeIdentifier: utType.identifier,
			preferredMIMEType: utType.preferredMIMEType,
			localizedDescription: utType.localizedDescription,
			isDynamic: utType.isDynamic,
			conformsTo: conformsTo
		)
	}
}

// MARK: - Config Loading
struct ConfigManager {
	static func loadConfig(from path: String) {
		// TODO: Implement configuration loading
		logger.notice("Configuration loading from \(path) not yet implemented")
	}
}

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
