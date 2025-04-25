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
        var fileType: String?

        @Option(name: .long, help: "A URL scheme. ex: mailto.")
        var scheme: String?

        @Option(name: .long, help: "A file class. ex: image")
        var type: Supertypes?

        mutating func run() async throws {
            if ext != nil && scheme != nil && type != nil {
                throw InfatError.conflictingOptions(
                    error:
                        "Cannot use --ext, --type, and --scheme together. They are mutually exclusive."
                )
            } else if ext != nil && scheme != nil {
                throw InfatError.conflictingOptions(
                    error:
                        "Cannot use --ext and --scheme together. They are mutually exclusive."
                )
            }
            if let fType = ext {
                try await setDefaultApplication(
                    appName: appName,
                    ext: fType)
            } else if let schm = scheme {
                try setURLHandler(appName: appName, scheme: schm)
                print("Successfully bound \(appName) to \(schm)")
            } else if let superType = type {
                if let sUTI = superType.utType {
                    try await setDefaultApplication(
                        appName: appName,
                        supertype: sUTI)
                }
                print(
                    "Set default app for type \(superType) to \(appName)"
                )
            }
        }
    }
}
