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

// MARK: - Main Command
@main
struct Infat: ParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "A tool to interact with NSWorkspace.",
		version: "0.1.0",
		subcommands: [List.self, Set.self, Info.self]
	)

	@Option(name: [.short, .long], help: "Path to the configuration file.")
	var config: String?

	mutating func run() throws {
		if let configPath = config {
			logger.info("Using configuration file: \(configPath)")
			ConfigManager.loadConfig(from: configPath)
		}
	}
}

// MARK: - List Subcommand
extension Infat {
	struct List: ParsableCommand {
		static let configuration = CommandConfiguration(abstract: "Lists something (example).")

		@Flag(name: [.short, .long], help: "List all items.")
		var all: Bool = false

		@Argument(help: "Close search to a specific application, role, or type")
		var identifier: String? = nil

		mutating func run() throws {
			logger.info("Executing 'list' subcommand with all=\(all)")

			if all {
				logger.info("Listing all items...")
				// TODO: Implement comprehensive listing
			} else {
				logger.info("Listing filtered items for: \(identifier ?? "all")")
				// TODO: Implement filtered listing
			}
		}
	}
}

// MARK: - Set Subcommand
extension Infat {
	struct Set: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Sets an application association.")

		@Argument(help: "The name of the application.")
		var appName: String

		@Argument(help: "The file type to associate.")
		var fileType: String

		@Argument(help: "OPTIONAL: The role for the association.")
		var role: String? = nil

		mutating func run() throws {
			logger.info("Executing 'set' subcommand")
			logger.info(
				"Setting association: App='\(appName)', File='\(fileType)', Role='\(role ?? "default")'"
			)

			do {

				let applications = try FileSystemUtilities.findApplications(containing: appName)
				print("Found applications: \(applications)")

				let utiInfo = try FileSystemUtilities.deriveUTIFromExtension(extention: fileType)
				print(utiInfo.description)

				print(try getCFBundleURLNames(appName: applications[1]))

				// TODO: Implement the actual association setting
				logger.notice("File association setting not yet implemented")
			} catch let error as InfatError {
				logger.error("\(error.localizedDescription)")
				throw error
			} catch {
				logger.error("Unexpected error: \(error.localizedDescription)")
				throw error
			}
		}
	}
}

// MARK: - Info Subcommand
extension Infat {
	struct Info: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Displays system information (example).")

		mutating func run() throws {
			logger.info("Executing 'info' subcommand")
			let workspace = NSWorkspace.shared

			if let frontApp = workspace.frontmostApplication {
				print("Active application: \(frontApp.localizedName ?? "Unknown")")
				print("Bundle identifier: \(frontApp.bundleIdentifier ?? "Unknown")")
			} else {
				print("No active application found")
			}
		}
	}
}

