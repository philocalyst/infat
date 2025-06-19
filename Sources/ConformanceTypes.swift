import ArgumentParser
import UniformTypeIdentifiers

// Define a selection of the UTI supertypes Apple defines
// Convert raw values to kebab-case for friendliness
enum Supertypes: String, CaseIterable, ExpressibleByArgument {
  // Text & Documents
  case text = "text"
  case plainText = "plain-text"
  case utf8PlainText = "utf8-plain-text"
  case utf16PlainText = "utf16-plain-text"
  case utf16ExternalPlainText = "utf16-external-plain-text"
  case rtf = "rtf"
  case rtfd = "rtfd"
  case flatRTFD = "flat-rtfd"
  case delimitedText = "delimited-text"
  case commaSeparatedText = "comma-separated-text"
  case tabSeparatedText = "tab-separated-text"
  case utf8TabSeparatedText = "utf8-tab-separated-text"
  case json = "json"
  case xml = "xml"
  case yaml = "yaml"
  case vCard = "vcard"
  case html = "html"
  case webArchive = "web-archive"

  // Images
  case image = "image"
  case png = "png"
  case jpeg = "jpeg"
  case gif = "gif"
  case tiff = "tiff"
  case bmp = "bmp"
  case svg = "svg"
  case webP = "webp"
  case heic = "heic"
  case heif = "heif"
  case livePhoto = "live-photo"
  case rawImage = "raw-image"
  case dng = "dng"
  case exr = "exr"
  case jpegXL = "jpeg-xl"

  // Audio
  case audio = "audio"
  case mp3 = "mp3"
  case wav = "wav"
  case aiff = "aiff"
  case midi = "midi"
  case mpeg4Audio = "mpeg4-audio"
  case appleProtectedMPEG4Audio = "apple-protected-mpeg4-audio"
  case playlist = "playlist"
  case m3uPlaylist = "m3u-playlist"

  // Video
  case video = "video"
  case movie = "movie"
  case quickTimeMovie = "quicktime-movie"
  case mpeg = "mpeg"
  case mpeg2Video = "mpeg2-video"
  case mpeg2TransportStream = "mpeg2-transport-stream"
  case mpeg4Movie = "mpeg4-movie"
  case appleProtectedMPEG4Video = "apple-protected-mpeg4-video"
  case avi = "avi"

  // Archives
  case archive = "archive"
  case zip = "zip"
  case gzip = "gzip"
  case bz2 = "bz2"
  case tarArchive = "tar-archive"
  case appleArchive = "apple-archive"

  // Source Code
  case sourceCode = "source-code"
  case cSource = "c-source"
  case cHeader = "c-header"
  case cPlusPlusSource = "c++-source"
  case cPlusPlusHeader = "c++-header"
  case objectiveCSource = "objective-c-source"
  case objectiveCPlusPlusSource = "objective-c++-source"
  case swiftSource = "swift-source"
  case assemblyLanguageSource = "assembly-language-source"
  case shellScript = "shell-script"
  case makefile = "makefile"
  case javaScript = "javascript"
  case pythonScript = "python-script"
  case rubyScript = "ruby-script"
  case perlScript = "perl-script"
  case phpScript = "php-script"
  case appleScript = "apple-script"
  case osaScript = "osa-script"
  case osaScriptBundle = "osa-script-bundle"

  // Filesystem & System
  case data = "data"
  case directory = "directory"
  case folder = "folder"
  case symbolicLink = "symbolic-link"
  case mountPoint = "mount-point"
  case aliasFile = "alias-file"
  case volume = "volume"
  case diskImage = "disk-image"
  case applicationBundle = "application-bundle"
  case framework = "framework"
  case executable = "executable"
  case unixExecutable = "unix-executable"
  case windowsExecutable = "windows-executable"

  // 3D Content
  case threeDContent = "3d-content"
  case usd = "usd"
  case usdz = "usdz"
  case realityFile = "reality-file"
  case sceneKitScene = "scene-kit-scene"
  case arReferenceObject = "ar-reference-object"

  // Fonts
  case font = "font"

  // Cryptographic Files
  case pkcs12 = "pkcs12"
  case x509Certificate = "x509-certificate"

  // URLs
  case url = "url"
  case fileURL = "file-url"
  case urlBookmarkData = "url-bookmark-data"

  // Property Lists
  case propertyList = "property-list"
  case xmlPropertyList = "xml-property-list"
  case binaryPropertyList = "binary-property-list"

  // Miscellaneous
  case log = "log"
  case bookmark = "bookmark"
  case internetLocation = "internet-location"
  case internetShortcut = "internet-shortcut"

  // Computed property to get the actual UTType
  var utType: UTType? {
    switch self {
    case .text: return .text
    case .plainText: return .plainText
    case .utf8PlainText: return .utf8PlainText
    case .utf16PlainText: return .utf16PlainText
    case .utf16ExternalPlainText: return .utf16ExternalPlainText
    case .rtf: return .rtf
    case .rtfd: return .rtfd
    case .flatRTFD: return .flatRTFD
    case .delimitedText: return .delimitedText
    case .commaSeparatedText: return .commaSeparatedText
    case .tabSeparatedText: return .tabSeparatedText
    case .utf8TabSeparatedText: return .utf8TabSeparatedText
    case .json: return .json
    case .xml: return .xml
    case .yaml: return .yaml
    case .vCard: return .vCard
    case .html: return .html
    case .webArchive: return .webArchive
    case .image: return .image
    case .png: return .png
    case .jpeg: return .jpeg
    case .gif: return .gif
    case .tiff: return .tiff
    case .bmp: return .bmp
    case .svg: return .svg
    case .webP: return .webP
    case .heic: return .heic
    case .heif: return .heif
    case .livePhoto: return .livePhoto
    case .rawImage: return .rawImage
    case .dng: return .dng
    case .exr: return .exr
    case .jpegXL: return .jpegxl
    case .audio: return .audio
    case .mp3: return .mp3
    case .wav: return .wav
    case .aiff: return .aiff
    case .midi: return .midi
    case .mpeg4Audio: return .mpeg4Audio
    case .appleProtectedMPEG4Audio: return .appleProtectedMPEG4Audio
    case .playlist: return .playlist
    case .m3uPlaylist: return .m3uPlaylist
    case .video: return .video
    case .movie: return .movie
    case .quickTimeMovie: return .quickTimeMovie
    case .mpeg: return .mpeg
    case .mpeg2Video: return .mpeg2Video
    case .mpeg2TransportStream: return .mpeg2TransportStream
    case .mpeg4Movie: return .mpeg4Movie
    case .appleProtectedMPEG4Video: return .appleProtectedMPEG4Video
    case .avi: return .avi
    case .archive: return .archive
    case .zip: return .zip
    case .gzip: return .gzip
    case .bz2: return .bz2
    case .tarArchive: return .tarArchive
    case .appleArchive: return .appleArchive
    case .sourceCode: return .sourceCode
    case .cSource: return .cSource
    case .cHeader: return .cHeader
    case .cPlusPlusSource: return .cPlusPlusSource
    case .cPlusPlusHeader: return .cPlusPlusHeader
    case .objectiveCSource: return .objectiveCSource
    case .objectiveCPlusPlusSource: return .objectiveCPlusPlusSource
    case .swiftSource: return .swiftSource
    case .assemblyLanguageSource: return .assemblyLanguageSource
    case .shellScript: return .shellScript
    case .makefile: return .makefile
    case .javaScript: return .javaScript
    case .pythonScript: return .pythonScript
    case .rubyScript: return .rubyScript
    case .perlScript: return .perlScript
    case .phpScript: return .phpScript
    case .appleScript: return .appleScript
    case .osaScript: return .osaScript
    case .osaScriptBundle: return .osaScriptBundle
    case .data: return .data
    case .directory: return .directory
    case .folder: return .folder
    case .symbolicLink: return .symbolicLink
    case .mountPoint: return .mountPoint
    case .aliasFile: return .aliasFile
    case .volume: return .volume
    case .diskImage: return .diskImage
    case .applicationBundle: return .applicationBundle
    case .framework: return .framework
    case .executable: return .executable
    case .unixExecutable: return .unixExecutable
    case .windowsExecutable: return .exe
    case .threeDContent: return .threeDContent
    case .usd: return .usd
    case .usdz: return .usdz
    case .realityFile: return .realityFile
    case .sceneKitScene: return .sceneKitScene
    case .arReferenceObject: return .arReferenceObject
    case .font: return .font
    case .pkcs12: return .pkcs12
    case .x509Certificate: return .x509Certificate
    case .url: return .url
    case .fileURL: return .fileURL
    case .urlBookmarkData: return .urlBookmarkData
    case .propertyList: return .propertyList
    case .xmlPropertyList: return .xmlPropertyList
    case .binaryPropertyList: return .binaryPropertyList
    case .log: return .log
    case .bookmark: return .bookmark
    case .internetLocation: return .internetLocation
    case .internetShortcut: return .internetShortcut
    }
  }

  // Map from string to enum
  static func fromString(_ string: String) -> Supertypes? {
    return Supertypes(rawValue: string)
  }

  // Map from enum to string
  func toString() -> String {
    return self.rawValue
  }
}
