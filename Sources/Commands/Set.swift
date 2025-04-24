import ArgumentParser
import Logging

extension Infat {
    struct Set: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Sets an application association."
        )
        @Argument(help: "The name of the application.")
        var appName: String

        @Option(name: .long, help: "A file extension without leading dot.")
        var fileType: String?

        @Option(name: .long, help: "A URL scheme ex - mailto.")
        var scheme: String?

        mutating func run() throws {
            if fileType != nil && scheme != nil {
                throw InfatError.conflictingOptions(
                    error:
                        "Cannot use --file-type and --scheme together. They are mutually exclusive."
                )
            }
            if let fType = fileType {
                try setDefaultApplication(
                    appName: appName,
                    fileType: fType)
            } else if let schm = scheme {
                try setURLHandler(appName: appName, scheme: schm)
                print("Successfully bound \(appName) to \(schm)")
            }
        }
    }
}
