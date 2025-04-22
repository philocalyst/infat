import AppKit
import ArgumentParser
import Logging

extension Infat {
    struct Info: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Displays system information."
        )

        mutating func run() throws {
            let workspace = NSWorkspace.shared
            guard let front = workspace.frontmostApplication else {
                throw InfatError.noActiveApplication
            }
            logger.notice("Active app: \(front.localizedName ?? "Unknown")")
            logger.notice("Bundle ID: \(front.bundleIdentifier ?? "Unknown")")
        }
    }
}
