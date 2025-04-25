import ArgumentParser
import Foundation
import Logging

import class Foundation.ProcessInfo

var logger = Logger(label: "com.philocalyst.infat")

@main
struct Infat: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A tool to assign default openers for filetypes",
        version: "0.1.0",
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
        let level: Logger.Level = verbose ? .trace : (quiet ? .critical : .error)
        LoggingSystem.bootstrap { label in
            var h = StreamLogHandler.standardOutput(label: label)
            h.logLevel = level
            return h
        }
        logger = Logger(label: "com.philocalyst.infat")
    }

    mutating func run() async throws {
        if let cfg = config {
            try await ConfigManager.loadConfig(from: cfg)
        } else {
            // No config path passed, try to load from XDG location:
            if let configurationDirectory = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"] {
                try await ConfigManager.loadConfig(
                    from: configurationDirectory.appending("/infat").appending("/config.toml"))
            }
        }
    }
}
