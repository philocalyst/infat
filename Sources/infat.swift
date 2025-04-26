import ArgumentParser
import Foundation
import Logging

import class Foundation.ProcessInfo

var logger = Logger(label: "com.philocalyst.infat")

@main
struct Infat: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Declaritively set assocations for URLs and files",
        version: "2.1.0",
        subcommands: [Info.self, Set.self]
    )

    @Option(
        name: [.short, .long],
        help: "Path to the configuration file.")
    var config: String?

    @Flag(
        name: [.short, .long],
        help: "Enable verbose logging.")
    var verbose = false

    @Flag(
        name: [.short, .long],
        help: "Quiet output.")
    var quiet = false

    func validate() throws {
        let level: Logger.Level = verbose ? .trace : (quiet ? .critical : .warning)
        LoggingSystem.bootstrap { label in
            var h = StreamLogHandler.standardOutput(label: label)
            h.logLevel = level
            return h
        }
        logger = Logger(label: "com.philocalyst.infat")
    }

    mutating func run() async throws {
        // First check if a config was passed through the CLI. Then check if one was found at the XDG config home. If neither, error.
        if let cfg = config {
            try await ConfigManager.loadConfig(from: cfg)
        } else {
            // No config path passed, try to load from XDG location:
            if let configurationDirectory = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] {
                try await ConfigManager.loadConfig(
                    from: configurationDirectory.appending("/infat").appending("/config.toml"))
            } else {
                print(
                    "Did you mean to pass in a config? Use -c or put one at XDG_CONFIG_HOME/infat/config.toml"
                )
                throw InfatError.missingOption
            }
        }
    }
}
