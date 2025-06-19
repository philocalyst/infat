import ArgumentParser
import Foundation
import Logging
import TOMLKit

struct LaunchServices: Encodable, Decodable {
  let LSHandlers: [Handler]
}

struct Handler: Decodable, Encodable {
  let LSHandlerContentType: String?
  let LSHandlerRoleAll: String?
  let LSHandlerRoleViewer: String?
  let LSHandlerPreferredVersions: [String: String]?
  let LSHandlerURLScheme: String?
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
