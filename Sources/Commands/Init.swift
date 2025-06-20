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
    @OptionGroup var globalOptions: GlobalOptions

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

          let app: String

          do {
            app = try getAppName(from: app_bundle)
          } catch InfatError.applicationNotFound(let name) {
            // Only throw for real if not robust
            if !globalOptions.robust {
              throw InfatError.applicationNotFound(name: name)
            }

            logger.warning(
              "Application '\(name)' not found ")
            continue
            // Otherwise just eat that thing up
          } catch {
            // propogate the rest
            throw error
          }

          if let scheme = item.LSHandlerURLScheme {
            schemesDict[scheme] = app
          } else if let raw_type = item.LSHandlerContentType {
            // Since these are already verified and added to the launch services, we can assume they can be converted
            let type = UTType(raw_type).unsafelyUnwrapped
            let supertype: Supertypes
            if let supahtype = Supertypes.allCases.first(where: { $0.utType == type }) {
              supertype = supahtype
            } else {
              logger.warning("Cannot find supertype for \(type)")
              continue
            }

            typesDict[supertype.toString()] = app
          } else if let tag_class = item.LSHandlerContentTagClass,
            tag_class == "public.filename-extension"
          {
            // Guard against the condition that it doesn't exist, everything's variable
            guard let ext = item.LSHandlerContentTag else {
              logger.warning(
                "Blank association for \(item)")
              continue
            }

            extensionsDict[ext] = app
          }
        } else {
          continue
        }
      }

      let encoder = TOMLEncoder()

      let tomlStructure: [String: Dictionary] = [
        "extensions": extensionsDict,
        "schemes": schemesDict,
        "types": typesDict,
      ]

      // Encode the nested dictionary to TOML
      let encodedTOML = try encoder.encode(tomlStructure)

      if let cfg = globalOptions.config {
        if let url = URL(string: cfg) {
          try encodedTOML.write(to: url, atomically: true, encoding: .utf8)
        }
      } else {
        // No config path passed, try XDG‐compliant locations:
        let searchPaths = getConfig()
        for url in searchPaths {
          try encodedTOML.write(to: url, atomically: true, encoding: .utf8)
          return
        }

        // Nothing found → error
        print(
          "Did you mean to pass in a config? Use -c or put one at " + "\(searchPaths[0].path)"
        )
        throw InfatError.missingOption
      }
    }
  }
}
