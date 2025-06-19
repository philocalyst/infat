import AppKit
import ArgumentParser
import Foundation
import Logging
import TOMLKit
import UniformTypeIdentifiers

struct LaunchServices: Encodable, Decodable, Sequence {
  let LSHandlers: [Handler]

  func makeIterator() -> Array<Handler>.Iterator {
    return LSHandlers.makeIterator()
  }
}

struct Handler: Decodable, Encodable {
  // Content type identification
  let LSHandlerContentType: String?
  let LSHandlerContentTag: String?
  let LSHandlerContentTagClass: String?

  // URL scheme handling
  let LSHandlerURLScheme: String?

  // Role assignments
  let LSHandlerRoleAll: String?
  let LSHandlerRoleViewer: String?
  let LSHandlerRoleEditor: String?

  // Version and metadata
  let LSHandlerPreferredVersions: [String: String]?
  let LSHandlerModificationDate: Double?
}

extension Infat {
  struct Init: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Initalizes a config with the currently set associations"
    )

    mutating func run() async throws {
      guard let homeDirectory = FileManager.default.homeDirectoryForCurrentUser as URL? else {
        throw InfatError.pathExpansionError(path: "Home directory")
      }

      // App on the left
      var typesDict: [String: String] = [:]
      var extensionsDict: [String: String] = [:]
      var schemesDict: [String: String] = [:]

      let launchServices =
        homeDirectory
        .appendingPathComponent("Library")
        .appendingPathComponent("Preferences")
        .appendingPathComponent("com.apple.LaunchServices")
        .appendingPathComponent("com.apple.launchservices.secure.plist")

      let launchServicesData = try Data(contentsOf: launchServices)

      let decoder = PropertyListDecoder()
      let ls_data = try decoder.decode(LaunchServices.self, from: launchServicesData)

      for item in ls_data {
        if let app_bundle = item.LSHandlerRoleAll {
          // This is what malformed apps manifest as I believe?
          guard app_bundle != "-" else {
            continue
          }

          // Get the app name, as we're observing bundle ID's
          let workspace = NSWorkspace.shared
          let appURL = workspace.urlForApplication(withBundleIdentifier: app_bundle)
            .unsafelyUnwrapped

          let app: String

          if let bundle = Bundle(url: appURL) {
            // Try to get the display name first (localized name)
            let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String

            // Fallback to the default name if display name is not available
            app =
              displayName
              ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Unknown")
          } else {
            throw InfatError.operationTimeout
          }

          if let scheme = item.LSHandlerURLScheme {
            schemesDict[app] = scheme
          } else if let raw_type = item.LSHandlerContentType {
            // Since these are already verified and added to the launch services, we can assume they can be converted
            let type = UTType(raw_type).unsafelyUnwrapped
          } else if let tag_class = item.LSHandlerContentTagClass,
            tag_class == "public.filename-extension"
          {
            // Guard against the condition that it doesn't exist, everything's variable
            guard let ext = item.LSHandlerContentTag else {
              continue
            }

            extensionsDict[app] = ext
          }
        } else {
          continue
        }
      }

      print(schemesDict)

      let encoder = TOMLEncoder()

      let output = try encoder.encode(ls_data)

    }
  }
}
