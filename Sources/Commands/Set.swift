import ArgumentParser
import Logging

extension Infat {
  struct Set: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "Sets an application association."
    )
    @Argument(help: "The name of the application.")
    var appName: String

    @Option(name: .long, help: "A file extension without leading dot.")
    var ext: String?

    @Option(name: .long, help: "A URL scheme. ex: mailto.")
    var scheme: String?

    @Option(name: .long, help: "A file class. ex: image")
    var type: Supertypes?

    @Flag(name: .long, help: "Ignore missing app errors")
    var robust: Bool = false

    mutating func run() async throws {
      let providedCount = [scheme != nil, ext != nil, type != nil]
        .filter { $0 }
        .count

      guard providedCount > 0 else {
        throw InfatError.missingOption
      }

      guard providedCount == 1 else {
        throw InfatError.conflictingOptions(
          error:
            "Either --scheme, --type, or --ext must be provided, but not more than one."
        )
      }

      if let fType = ext {
        switch fType.lowercased() {
        case "html":
          // Route .html to the http URL handler
          try setURLHandler(appName: appName, scheme: "http")
          print("Successfully bound \(appName) to http")
        default:
          do {
            try await setDefaultApplication(
              appName: appName,
              ext: fType
            )
          } catch InfatError.applicationNotFound(let name) {
            // Only throw for real if not robust
            if !robust {
              throw InfatError.applicationNotFound(name: name)
            }
            print(
              "Application '\(appName)' not found but ignoring due to passed options".bold().red())
            return
            // Otherwise just eat that thing up
          } catch {
            // propogate the rest
            throw error
          }
          print("Successfully bound \(appName) to \(fType)".italic())
        }

      } else if let schm = scheme {
        switch schm.lowercased() {
        case "https":
          // Route https to the http URL handler
          try setURLHandler(appName: appName, scheme: "http")
          print("Successfully bound \(appName) to http")
        default:
          try setURLHandler(
            appName: appName,
            scheme: schm
          )
          print("Successfully bound \(appName) to \(schm)".italic())
        }

      } else if let superType = type {
        if let sUTI = superType.utType {
          try await setDefaultApplication(
            appName: appName,
            supertype: sUTI
          )
        }
        print("Set default app for type \(superType) to \(appName)".italic())
      }
    }
  }
}
