import AppKit
import Foundation
import Logging
import PListKit
import UniformTypeIdentifiers

func getBundleIdentifier(appURL: URL) throws -> String? {
    let plistURL =
        appURL
        .appendingPathComponent("Contents")
        .appendingPathComponent("Info.plist")
    do {
        let plist = try DictionaryPList(url: plistURL)
        return plist.root.string(key: "CFBundleIdentifier").value
    } catch {
        throw InfatError.plistReadError(
            path: plistURL.path,
            underlyingError: error)
    }
}

func setURLHandler(appName: String, scheme: String) throws {
    let apps = try FileSystemUtilities.findApplications()
    let applicationURL = findApplication(applications: apps, key: appName)
    if let appURL = applicationURL {

        let appBundleIdentifier = try getBundleIdentifier(appURL: appURL)
        if let appBundleID = appBundleIdentifier {
            // Register the URL in the launch services database, and yes, update information for the app if it already exists.
            let registerResultCode = LSRegisterURL(appURL as CFURL, true)
            if registerResultCode != 0 {
                throw InfatError.cannotRegisterURL(error: registerResultCode)
            }

            // Takes URL scheme and bundle ID, as CF strings and sets the handler using a deprecated method. Risky code, until big papa Apple releases an alternative.
            let setResultCode = LSSetDefaultHandlerForURLScheme(
                scheme as CFString, appBundleID as CFString)
            if setResultCode != 0 {
                throw InfatError.cannotRegisterURL(error: setResultCode)
            }
        } else {
            throw InfatError.cannotSetURL(appName: appURL.path())
        }
    }
}

func findApplication(applications: [URL], key: String) -> URL? {
    for app in applications {
        let name = app.deletingPathExtension().lastPathComponent
        if name == key {
            logger.debug("Matched application: \(app.path)")
            return app
        }
    }
    logger.warning("No application found matching: \(key)")
    return nil
}

// Private helper function containing the core logic
private func _setDefaultApplication(
    appName: String, appURL: URL, typeIdentifier: UTType, inputDescription: String
) async throws {
    let workspace = NSWorkspace.shared
    try await workspace.setDefaultApplication(
        at: appURL,
        toOpen: typeIdentifier  // Use the modern API if possible
            // Note: The original API `toOpen:` taking a String UTI is deprecated.
            // Using `toOpenContentTypes:` which takes an array of UTIs is preferred.
            // If you MUST use the old API:
            // try await workspace.setDefaultApplication(at: appURL, toOpen: typeIdentifier)
    )
    logger.info("Set default app for \(inputDescription) to \(appName)")
}

/// Sets the default application for a given file type specified by its extension.
func setDefaultApplication(appName: String, ext: String) async throws {
    let apps = try FileSystemUtilities.findApplications()
    guard let appURL = findApplication(applications: apps, key: appName) else {
        throw InfatError.applicationNotFound(name: appName)
    }

    // Derive UTType from the extension string
    guard let uti = UTType(filenameExtension: ext.lowercased()) else {
        throw InfatError.couldNotDeriveUTI(msg: ext)
    }

    try await _setDefaultApplication(
        appName: appName,
        appURL: appURL,
        typeIdentifier: uti,  // Pass the UTI string identifier
        inputDescription: ".\(ext)"  // For logging clarity
    )
}

/// Sets the default application for a given file type specified by its UTType.
func setDefaultApplication(appName: String, supertype: UTType) async throws {
    let apps = try FileSystemUtilities.findApplications()
    guard let appURL = findApplication(applications: apps, key: appName) else {
        throw InfatError.applicationNotFound(name: appName)
    }

    try await _setDefaultApplication(
        appName: appName,
        appURL: appURL,
        typeIdentifier: supertype,
        inputDescription: supertype.description
    )
}
