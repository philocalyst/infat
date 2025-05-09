import UniformTypeIdentifiers

struct FileUTIInfo {
  let typeIdentifier: UTType
  let preferredMIMEType: String?
  let localizedDescription: String?
  let isDynamic: Bool
  let conformsTo: [String]

  var description: String {
    var output = "UTI: \(typeIdentifier)\n"
    if let mimeType = preferredMIMEType {
      output += "MIME Type: \(mimeType)\n"
    }
    if let description = localizedDescription {
      output += "Description: \(description)\n"
    }
    output += "Is Dynamic: \(isDynamic ? "Yes" : "No")\n"
    if !conformsTo.isEmpty {
      output += "Conforms To: \(conformsTo.joined(separator: ", "))\n"
    }
    return output
  }
}
