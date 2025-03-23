import AppKit
import ArgumentParser
import Foundation
import Logging
import PListKit
import Toml
import UniformTypeIdentifiers

var logger = Logger(label: "com.example.burt")

// MARK: - Error Definitions
enum InfatError: Error, LocalizedError {
	case cannotDetermineUTI
	case unsupportedOSVersion
	case directoryReadError(path: String, underlyingError: Error)
	case pathExpansionError(path: String)
	case applicationNotFound(name: String)
	case plistReadError(path: String, underlyingError: Error)
	case defaultAppSettingError(underlyingError: Error)
	case noActiveApplication
	case configurationLoadError(path: String, underlyingError: Error)
	case operationTimeout

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
		case .plistReadError(let path, let error):
			return "Error reading or parsing Info.plist at \(path): \(error.localizedDescription)"
		case .defaultAppSettingError(let error):
			return "Failed to set default application: \(error.localizedDescription)"
		case .noActiveApplication:
			return "No active application found"
		case .configurationLoadError(let path, let error):
			return "Failed to load configuration from \(path): \(error.localizedDescription)"
		case .operationTimeout:
			return "Operation timed out"
		}
	}
}

struct FileUTIInfo {
	let typeIdentifier: UTType
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
	static func findApplications() throws -> [URL] {
		let fileManager = FileManager.default
		let homeDirectory = fileManager.homeDirectoryForCurrentUser.path()
		var allAppURLs: [URL] = []

		// Define the applications directories to search
		// User-space, Root-space, and System-space
		let applicationPaths = [
			"/Applications/",
			"/System/Applications/",
			(homeDirectory + "/Applications/"),
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
				// Continue to next directory instead of failing completely
			}
		}

		if allAppURLs.isEmpty {
			logger.error("No applications found in any search directory")
			throw InfatError.directoryReadError(
				path: "All application directories",
				underlyingError: NSError(
					domain: "com.example.burt", code: 1,
					userInfo: [NSLocalizedDescriptionKey: "No applications found"]))
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
			logger.error("Cannot determine UTI for extension: .\(extention)")
			throw InfatError.cannotDetermineUTI
		}

		let conformsTo = commonUTTypes.filter { utType.conforms(to: $0) }.map { $0.identifier }
		logger.debug("Determined UTI \(utType.identifier) for \(extention)")

		return FileUTIInfo(
			typeIdentifier: utType,
			preferredMIMEType: utType.preferredMIMEType,
			localizedDescription: utType.localizedDescription,
			isDynamic: utType.isDynamic,
			conformsTo: conformsTo
		)
	}
}

// MARK: - Config Loading
struct ConfigManager {
	static func loadConfig(from path: String) throws {
		do {
			// TODO: Implement configuration loading
			logger.notice("Configuration loading from \(path) not yet implemented")
		} catch {
			logger.error("Failed to load configuration from \(path): \(error.localizedDescription)")
			throw InfatError.configurationLoadError(path: path, underlyingError: error)
		}
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

	@Flag(name: [.long], help: "Enable debug logging.")
	var debug: Bool = false

	@Flag(name: [.short, .long], help: "Enable verbose logging (info, notice, warning levels).")
	var verbose: Bool = false

	// Custom validation for logging flags
	func validate() throws {
		// Configure logger based on flags
		var logLevel: Logger.Level = .critical

		if debug {
			logLevel = .debug
		} else if verbose {
			logLevel = .info
		} else {
			logLevel = .error
		}

		// Set the log level
		LoggingSystem.bootstrap { label in
			var handler = StreamLogHandler.standardOutput(label: label)
			handler.logLevel = logLevel
			return handler
		}

		logger = Logger(label: "com.example.burt")
		logger.debug("Debug logging enabled")
		logger.info("Verbose logging enabled")
	}

	mutating func run() throws {
		logger.debug("Initializing Infat")

		if let configPath = config {
			logger.info("Using configuration file: \(configPath)")
			try ConfigManager.loadConfig(from: configPath)
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
				let workspace = NSWorkspace.shared
				let applications = try FileSystemUtilities.findApplications()
				guard let app = findApplication(applications: applications, key: appName) else {
					logger.error("Application not found: \(appName)")
					throw InfatError.applicationNotFound(name: appName)
				}

				logger.info("Found application at: \(app.path)")
				let utiInfo = try FileSystemUtilities.deriveUTIFromExtension(extention: fileType)
				logger.debug("UTI for .\(fileType): \(utiInfo.typeIdentifier.identifier)")

				// Check if we can actually get the current default app
				if let currentDefaultApp = workspace.urlForApplication(
					toOpen: utiInfo.typeIdentifier)
				{
					logger.debug("Current default app for .\(fileType): \(currentDefaultApp.path)")
				} else {
					logger.info("No current default app for .\(fileType)")
				}

				logger.info("Attempting to set default application...")
				let semaphore = DispatchSemaphore(value: 0)
				var operationError: Error?

				workspace.setDefaultApplication(
					at: app,
					toOpen: utiInfo.typeIdentifier
				) { error in
					operationError = error
					semaphore.signal()
				}

				// Wait for the operation to complete with timeout handling
				let result = semaphore.wait(timeout: .now() + 10)  // Ten second timeout

				if result == .timedOut {
					logger.critical("Operation timed out after 10 seconds")
					throw InfatError.operationTimeout
				}

				if let error = operationError {
					logger.critical(
						"Failed to set default application: \(error.localizedDescription)")
					throw InfatError.defaultAppSettingError(underlyingError: error)
				}

				logger.info("Successfully set default application")
			} catch let error as InfatError {
				logger.critical("Error: \(error.localizedDescription)")
				throw error
			} catch {
				logger.critical("Unexpected error: \(error.localizedDescription)")
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
				logger.notice("Active application: \(frontApp.localizedName ?? "Unknown")")
				logger.notice("Bundle identifier: \(frontApp.bundleIdentifier ?? "Unknown")")
			} else {
				logger.error("No active application found")
				throw InfatError.noActiveApplication
			}
		}
	}
}

func getBundleName(appName: URL) throws -> String? {
	let plistURL = appName.appendingPathComponent("Contents").appendingPathComponent("Info.plist")
	do {
		let plist = try DictionaryPList(file: plistURL.path)
		return plist.root.string(key: "CFBundleIdentifier").value
	} catch {
		logger.error(
			"Error reading or parsing Info.plist at \(plistURL.path): \(error.localizedDescription)"
		)
		throw InfatError.plistReadError(path: plistURL.path, underlyingError: error)
	}
}

func findApplication(applications: [URL], key: String) -> URL? {
	for application in applications {
		let appNameWithExtension = application.lastPathComponent
		if let appName = appNameWithExtension.split(separator: ".").first {
			if String(appName) == key {
				logger.debug("Found matching application: \(application.path)")
				return application
			}
		}
	}
	logger.warning("No application found matching: \(key)")
	return nil
}
