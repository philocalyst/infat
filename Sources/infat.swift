import ArgumentParser
import Logging
import Foundation

var logger = Logger(label: "com.example.burt")

@main
struct Infat: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A tool to assign default openers for filetypes",
        version: "0.1.0",
        subcommands: [List.self, Set.self, Info.self]
    )

    @Option(name: [.short, .long],
            help: "Path to the configuration file.")
    var config: String?

    @Flag(name: [.short, .long],
          help: "Enable verbose logging.")
    var verbose = false

    @Flag(name: [.short, .long],
          help: "Quiet output.")
    var quiet = false

    func validate() throws {
        let level: Logger.Level = verbose ? .debug :
            (quiet ? .critical : .error)
        LoggingSystem.bootstrap { label in
            var h = StreamLogHandler.standardOutput(label: label)
            h.logLevel = level
            return h
        }
        logger = Logger(label: "com.example.burt")
    }

    mutating func run() throws {
        if let cfg = config {
            try ConfigManager.loadConfig(from: cfg)
        }
    }
}
