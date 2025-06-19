import ArgumentParser
import Foundation
import Logging

import class Foundation.ProcessInfo

var logger = Logger(label: "com.philocalyst.infat")

// Globals
struct GlobalOptions: ParsableArguments {
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

  @Flag(name: .long, help: "Ignore missing app errors")
  var robust: Bool = false
}

@main
struct Infat: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Declaritively set assocations for URLs and files",
    version: "2.5.0",
    subcommands: [Info.self, Set.self, Init.self]
  )

  @OptionGroup var globalOptions: GlobalOptions

  func validate() throws {
    let level: Logger.Level =
      globalOptions.verbose ? .trace : (globalOptions.quiet ? .critical : .warning)
    LoggingSystem.bootstrap { label in
      var h = StreamLogHandler.standardOutput(label: label)
      h.logLevel = level
      return h
    }
    logger = Logger(label: "com.philocalyst.infat")
  }

  mutating func run() async throws {
    // First check if a config was passed through the CLI. Then check if one was found at the XDG config home. If neither, error.
    if let cfg = globalOptions.config {
      try await ConfigManager.loadConfig(from: cfg, robust: globalOptions.robust)
    } else {
      // No config path passed, try XDG‐compliant locations:
      let searchPaths = getConfig()
      for url in searchPaths {
        try await ConfigManager.loadConfig(from: url.path, robust: globalOptions.robust)
        return
      }

      // Nothing found → error
      print(
        "Did you mean to pass in a config? Use -c or put one at " + "\(searchPaths[0].path)"
      )
      throw InfatError.missingOption
    }
  }
}
