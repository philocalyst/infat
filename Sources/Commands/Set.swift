import ArgumentParser
import Logging

extension Infat {
    struct Set: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Sets an application association."
        )
        @Argument(help: "The name of the application.")
        var appName: String

        @Argument(help: "The file extension (no dot).")
        var fileType: String

        @Argument(help: "Optional role for the association.")
        var role: String?

        mutating func run() throws {
            try setDefaultApplication(
                appName: appName,
                fileType: fileType)
        }
    }
}
