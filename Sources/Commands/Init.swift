import ArgumentParser
import Foundation
import Logging
import TOMLKit

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
      let typesDict: [String: String] = [:]
      let extensionsDict: [String: String] = [:]
      let schemesDict: [String: String] = [:]

      let launchServices =
        homeDirectory
        .appendingPathComponent("Library")
        .appendingPathComponent("Preferences")
        .appendingPathComponent("com.apple.LaunchServices")
        .appendingPathComponent("com.apple.launchservices.secure.plist")

      let launchServicesData = try Data(contentsOf: launchServices)

      let decoder = PropertyListDecoder()
      let ls_data = try decoder.decode(LaunchServices.self, from: launchServicesData)

      var encoder = TOMLEncoder()

      let output = try encoder.encode(ls_data)

      print(output)
    }
  }
}
