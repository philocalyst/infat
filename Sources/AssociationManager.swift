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
    let applicationURL = try findApplication(named: appName)
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

func findApplication(named key: String) throws -> URL? {
    let fullKey = (key as NSString).expandingTildeInPath
    let fm = FileManager.default

    // |1| Normalize the key in case user provided a ".app" extension.
    let rawExt = (fullKey as NSString).pathExtension.lowercased()
    let baseName =
        rawExt == "app"
        ? (fullKey as NSString).deletingPathExtension
        : fullKey

    // |2| If this is a valid file‐system path or a file:// URL,
    // perform basic checks and return instantly if a .app bundle.

    let isFileURL = (URL(string: fullKey)?.isFileURL) ?? false
    if isFileURL || fm.fileExists(atPath: fullKey) {
        // Initalize properly depending on type of URL
        let url =
            isFileURL
            ? URL(string: fullKey)!
            : URL(fileURLWithPath: fullKey)

        let r = try url.resourceValues(
            forKeys: [.isDirectoryKey, .typeIdentifierKey]
        )
        // Final check, these attributes are required for app bundles.
        if r.isDirectory == true,
            let tid = r.typeIdentifier,
            let ut = UTType(tid),
            ut.conforms(to: .applicationBundle)
        {
            return url
        }
        return nil
    }

    // |3| Otherwise treat `key` as a provided app name: scan all installed .app bundles
    let installed = try FileSystemUtilities.findApplications()
    return installed.first {
        $0.deletingPathExtension()
            .lastPathComponent
            .caseInsensitiveCompare(baseName)
            == .orderedSame
    }
}

private func setDefaultApplication(
    appName: String, appURL: URL, typeIdentifier: UTType, inputDescription: String
) async throws {
    let workspace = NSWorkspace.shared
    do {
        try await workspace.setDefaultApplication(
            at: appURL,
            toOpen: typeIdentifier
        )
        // success!
    } catch {
        let nsErr = error as NSError
        // Detect the restriction
        let isFileOpenError =
            nsErr.domain == NSCocoaErrorDomain
            && nsErr.code == CocoaError.fileReadUnknown.rawValue

        guard isFileOpenError else {
            // Some other error—rethrow it
            throw error
        }

        // Fallback: call LSSetDefaultRoleHandlerForContentType directly
        guard let bundleID = try getBundleIdentifier(appURL: appURL)
        else {
            throw InfatError.applicationNotFound(name: appURL.path)
        }

        let utiCF = typeIdentifier.identifier as CFString
        let lsErr = LSSetDefaultRoleHandlerForContentType(
            utiCF,
            LSRolesMask.viewer,
            bundleID as CFString
        )
        guard lsErr == noErr else {
            // propagate the LaunchServices error
            throw InfatError.cannotRegisterURL(error: lsErr)
        }
    }
}

/// Sets the default application for a given file type specified by its extension.
func setDefaultApplication(appName: String, ext: String) async throws {
    guard let appURL = try findApplication(named: appName) else {
        throw InfatError.applicationNotFound(name: appName)
    }

    // Derive UTType from the extension string
    guard let uti = UTType(filenameExtension: ext) else {
        throw InfatError.couldNotDeriveUTI(msg: ext)
    }

    try await setDefaultApplication(
        appName: appName,
        appURL: appURL,
        typeIdentifier: uti,  // Pass the UTI string identifier
        inputDescription: ".\(ext)"  // For logging clarity
    )
}

/// Sets the default application for a given file type specified by its UTType.
func setDefaultApplication(appName: String, supertype: UTType) async throws {
    guard let appURL = try findApplication(named: appName) else {
        throw InfatError.applicationNotFound(name: appName)
    }

    try await setDefaultApplication(
        appName: appName,
        appURL: appURL,
        typeIdentifier: supertype,
        inputDescription: supertype.description
    )
}
