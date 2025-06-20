import ColorizeSwift
import Foundation
import Logging
import TOMLKit
import UniformTypeIdentifiers

struct ConfigManager {
  static func loadConfig(from configPath: String, robust: Bool) async throws {
    // Read and parse the TOML file
    let tomlContent = try String(
      contentsOf: URL(fileURLWithPath: configPath)
    )
    let tomlConfig = try TOMLTable(string: tomlContent)

    // Convenience names
    let extensionTableName = "extensions"
    let schemeTableName = "schemes"
    let typeTableName = "types"

    // Check upfront that at least one table is present
    let hasExtensions = tomlConfig[extensionTableName]?.table != nil
    let hasSchemes = tomlConfig[schemeTableName]?.table != nil
    let hasTypes = tomlConfig[typeTableName]?.table != nil

    guard hasExtensions || hasSchemes || hasTypes else {
      throw InfatError.noConfigTables(path: configPath)
    }

    // MARK: – Process [types]
    if let typeTable = tomlConfig[typeTableName]?.table {
      logger.info("Processing [types] associations...")
      print("\(typeTableName.uppercased().bold().underline())")
      for typeKey in typeTable.keys {
        // See if it has a corresponding UTTYPE
        let uttype = UTType(typeKey)
        guard let appName = typeTable[typeKey]?.string else {
          logger.warning(
            "Value for key '\(typeKey)' in [types] is not a string. Skipping."
          )
          continue
        }

        // Holding value
        var typem: Supertypes? = nil

        // If it already has a UType, AYE!! Skip
        if uttype != nil {
        } else if let supahhhType = Supertypes(rawValue: typeKey) {
          typem = supahhhType
        } else {
          logger.error(
            "Invalid type key '\(typeKey)' found in [types]. Skipping."
          )
          continue
        }

        let result = typem?.utType ?? uttype

        // If this is somehow invalid we in trouble!!
        if result == nil {
          logger.error(
            "Well-known type '\(typeKey)' not supported or invalid. Skipping."
          )
          throw InfatError.unsupportedOrInvalidSupertype(name: typeKey)
        }

        if result?.description == "com.apple.default-app.web-browser"
          || result?.description == "public.html"
        {
          try setURLHandler(appName: appName, scheme: "http")
          print("Set .\(result?.description) → \(appName) (routed to http)")
          continue
        }
        logger.debug(
          "Queueing default app for type \(typeKey) (\(result?.identifier)) → \(appName)"
        )
        do {
          try await setDefaultApplication(
            appName: appName,
            supertype: result!
          )
        } catch InfatError.applicationNotFound(let app) {
          if !robust {
            throw InfatError.applicationNotFound(name: appName)
          }
          print(
            "Application '\(app)' not found but ignoring "
              + "due to passed options"
              .bold().red()
          )
          // Just eat that thing up
        } catch {
          // propagate the rest
          throw error
        }
        print("Set type \(typeKey) → \(appName)")
      }
    } else {
      logger.debug("No [types] table found in \(configPath)")
    }

    // MARK: – Processs [extensions]
    if let extensionTable = tomlConfig[extensionTableName]?.table {
      logger.info("Processing [extensions] associations...")
      print("\(extensionTableName.uppercased().bold().underline())")
      for ext in extensionTable.keys {
        guard let appName = extensionTable[ext]?.string else {
          throw InfatError.tomlValueNotString(
            path: configPath,
            key: ext
          )
        }
        switch ext.lowercased() {
        case "html":
          // Route .html to the http URL handler
          try setURLHandler(appName: appName, scheme: "http")
          print("Set .\(ext) → \(appName) (routed to http)")
        default:
          do {
            try await setDefaultApplication(
              appName: appName,
              ext: ext
            )
          } catch InfatError.applicationNotFound(let app) {
            if !robust {
              throw InfatError.applicationNotFound(name: appName)
            }
            print(
              "Application '\(app)' not found but ignoring "
                + "due to passed options"
                .bold().red()
            )
            // Just eat that thing up
          } catch {
            // propagate the rest
            throw error
          }
          print("Set .\(ext) → \(appName)")
        }
      }
    } else {
      logger.debug("No [extensions] table found in \(configPath)")
    }

    // MARK: – Process [schemes]
    if let schemeTable = tomlConfig[schemeTableName]?.table {
      logger.info("Processing [schemes] associations...")
      print("\(schemeTableName.uppercased().bold().underline())")
      for scheme in schemeTable.keys {
        guard let appName = schemeTable[scheme]?.string else {
          throw InfatError.tomlValueNotString(
            path: configPath,
            key: scheme
          )
        }
        switch scheme.lowercased() {
        case "https":
          // Route https to the http URL handler
          try setURLHandler(appName: appName, scheme: "http")
          print("Set https → \(appName) (routed to http)")
        default:
          do {
            try setURLHandler(appName: appName, scheme: scheme)
          } catch InfatError.applicationNotFound(let app) {
            if !robust {
              throw InfatError.applicationNotFound(name: appName)
            }
            print(
              "Application '\(app)' not found but ignoring "
                + "due to passed options"
                .bold().red()
            )
            // Just eat that thing up
          } catch {
            // propagate the rest
            throw error
          }
          print("Set \(scheme) → \(appName)")
        }
      }
    } else {
      logger.debug("No [schemes] table found in \(configPath)")
    }
  }
}
