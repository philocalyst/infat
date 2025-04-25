import AppKit
import ArgumentParser
import Foundation
import PListKit
import UniformTypeIdentifiers

struct Info: ParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: """
			Lists file association information.
			"""
	)

	@Option(name: [.short, .long], help: "Application name (e.g., 'Google Chrome').")
	var app: String?

	@Option(name: [.short, .long], help: "File extension (without the dot, e.g., 'html').")
	var ext: String?

	mutating func run() throws {
		guard (app != nil) != (ext != nil) else {  // XOR check
			throw InfatError.conflictingOptions(
				error: "Either --app or --ext must be provided, but not both."
			)
		}

		if let appName = app {
			try listTypesForApp(appName: appName)
		} else if let fileExtension = ext {
			try listAppsForExtension(fileExtension: fileExtension)
		}
	}

	// ▰▰▰ Helper Methods ▰▰▰

	private func listTypesForApp(appName: String) throws {
		logger.info("Looking for types handled by '\(appName)'...")

		let apps = try FileSystemUtilities.findApplications()

		guard let appPath = findApplication(applications: apps, key: appName) else {
			throw InfatError.applicationNotFound(name: appName)
		}
		logger.info("Found application at: \(appPath)")

		let infoPlistPath =
			appPath
			.appendingPathComponent("Contents")
			.appendingPathComponent("Info.plist")

		guard FileManager.default.fileExists(atPath: infoPlistPath.path) else {
			throw InfatError.infoPlistNotFound(appPath: appPath.path)
		}

		let plist = try DictionaryPList(url: infoPlistPath)

		guard let documentTypes = plist.root.array(key: "CFBundleDocumentTypes").value
		else {
			print(
				"No 'CFBundleDocumentTypes' found in \(infoPlistPath). This app might not declare specific document types."
			)
			return
		}

		print("\nDeclared Document Types:")
		if documentTypes.isEmpty {
			print("  (None declared)")
			return
		}

		for item in documentTypes {
			if let docType = item as? PListDictionary {
				let typeName = docType
				print("  • \(typeName):")

				if let utis = docType["LSItemContentTypes"] as? [String], !utis.isEmpty {
					print("    - UTIs: \(utis.joined(separator: ", "))")
				} else {
					print("    - UTIs: (None specified)")
				}

				if let extensions = docType["CFBundleTypeExtensions"] as? [String],
					!extensions.isEmpty
				{
					print(
						"    - Extensions: \(extensions.map { ".\($0)" }.joined(separator: ", "))")
				} else {
					print("    - Extensions: (None specified)")
				}
				print("")
			}
		}
	}

	private func listAppsForExtension(fileExtension: String) throws {
		print("Looking for apps associated with '.\(fileExtension)'...")

		guard let uti = deriveUTIFromExtension(extension: fileExtension) else {
			throw InfatError.couldNotDeriveUTI(msg: fileExtension)
		}
		print("Derived UTI: \(uti.identifier)")

		let workspace = NSWorkspace.shared

		if let defaultAppURL = workspace.urlForApplication(toOpen: uti) {
			print("Default app: \(defaultAppURL.lastPathComponent) (\(defaultAppURL.path))")
		} else {
			print(
				"No default application registered for '.\(fileExtension)' (UTI: \(uti.identifier))."
			)
		}

		let allAppURLs = workspace.urlsForApplications(toOpen: uti)
		if !allAppURLs.isEmpty {
			print("\nAll registered apps:")
			allAppURLs.forEach { url in
				print("  • \(url.lastPathComponent) (\(url.path))")
			}
		} else {
			print(
				"No applications specifically registered for '.\(fileExtension)' (UTI: \(uti.identifier))."
			)
		}
	}

	private func deriveUTIFromExtension(extension ext: String) -> UTType? {
		return UTType(filenameExtension: ext)
	}
}
