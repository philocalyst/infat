import ArgumentParser
import Foundation
import Logging

struct LaunchServices: Decodable {
  let LSHandlers: [Handler]
}

struct Handler: Decodable {
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
      let fileURL = URL(
        fileURLWithPath:
          "/Users/philocalyst/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist"
      )
      let data = try Data(contentsOf: fileURL)

      let decoder = PropertyListDecoder()
      let ls_data = try decoder.decode(LaunchServices.self, from: data)

      print(ls_data)

    }
  }
}
