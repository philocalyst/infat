import AppKit
import Foundation
import Logging
import PListKit

func getBundleIdentifier(appURL: URL) throws -> String? {
    let plistURL =
        appURL
        .appendingPathComponent("Contents")
        .appendingPathComponent("Info.plist")
    do {
        let plist = try DictionaryPList(file: plistURL.path)
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

func setDefaultApplication(appName: String, fileType: String) async throws {
    let workspace = NSWorkspace.shared
    let apps = try FileSystemUtilities.findApplications()
    guard let appURL = findApplication(applications: apps, key: appName) else {
        throw InfatError.applicationNotFound(name: appName)
    }
    let utiInfo = try FileSystemUtilities.deriveUTIFromExtension(extention: fileType)

    try await workspace.setDefaultApplication(
        at: appURL,
        toOpen: utiInfo.typeIdentifier
    )
    logger.info("Set default app for .\(fileType) to \(appName)")
}
