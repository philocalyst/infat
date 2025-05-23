import Foundation
import Logging
import UniformTypeIdentifiers

struct FileSystemUtilities {
  static func findApplications() throws -> [URL] {
    let fileManager = FileManager.default
    let home = fileManager.homeDirectoryForCurrentUser.path
    var allAppURLs: [URL] = []
    let paths = [
      "/Applications/",
      "/System/Library/CoreServices/Applications/",
      "/System/Applications/",
      "\(home)/Applications/",
    ]
    for path in paths {
      do {
        let urls = try fileManager.contentsOfDirectory(
          at: URL(fileURLWithPath: path),
          includingPropertiesForKeys: nil,
          options: []
        )
        allAppURLs.append(contentsOf: urls)
        logger.debug("Found \(urls.count) items in \(path)")
      } catch {
        logger.debug("Could not read \(path): \(error.localizedDescription)")
      }
    }
    guard !allAppURLs.isEmpty else {
      throw InfatError.directoryReadError(
        path: "All application directories",
        underlyingError: NSError(
          domain: "com.philocalyst.infat", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "No applications found"]
        )
      )
    }
    return allAppURLs
  }

  static func deriveUTIFromExtension(ext: String) throws -> FileUTIInfo {
    guard #available(macOS 11.0, *) else {
      throw InfatError.unsupportedOSVersion
    }
    let commonUTTypes: [UTType] = [
      .content, .text, .plainText, .pdf,
      .image, .png, .jpeg, .gif,
      .audio, .mp3, .movie, .mpeg4Movie,
      .zip, .gzip, .archive,
    ]
    guard let utType = UTType(filenameExtension: ext) else {
      throw InfatError.couldNotDeriveUTI(msg: ext)
    }
    let conforms =
      commonUTTypes
      .filter { utType.conforms(to: $0) }
      .map { $0.identifier }
    logger.debug("Determined UTI \(utType.identifier) for .\(ext)")
    return FileUTIInfo(
      typeIdentifier: utType,
      preferredMIMEType: utType.preferredMIMEType,
      localizedDescription: utType.localizedDescription,
      isDynamic: utType.isDynamic,
      conformsTo: conforms
    )
  }
}
