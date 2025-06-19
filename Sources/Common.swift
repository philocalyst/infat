import ArgumentParser
import Foundation
import Logging

func getConfig() -> [URL] {
  // No config path passed, try XDG‐compliant locations:
  let env = ProcessInfo.processInfo.environment

  // |1| Determine XDG_CONFIG_HOME (or default to ~/.config)
  let homeDir = env["HOME"] ?? NSHomeDirectory()
  let xdgConfigHomePath = env["XDG_CONFIG_HOME"] ?? "\(homeDir)/.config"
  let xdgConfigHome = URL(fileURLWithPath: xdgConfigHomePath, isDirectory: true)

  // |2| Set up the per‐app relative path
  let appConfigSubpath = "infat/config.toml"

  // |3| Build the search list: user then system
  var searchPaths: [URL] = [
    xdgConfigHome.appendingPathComponent(appConfigSubpath)
  ]

  // If user has more than one config directory
  let systemConfigDirs =
    env["XDG_CONFIG_DIRS"]?
    .split(separator: ":")
    .map(String.init)
    ?? ["/etc/xdg"]

  for dir in systemConfigDirs {
    let url = URL(fileURLWithPath: dir, isDirectory: true)
      .appendingPathComponent(appConfigSubpath)
    searchPaths.append(url)
  }

  var results: [URL] = []

  // |4| Try each path in order
  for url in searchPaths {
    if FileManager.default.fileExists(atPath: url.path) {
      results.append(url)
    }
  }

  return results
}
