import ArgumentParser
import UniformTypeIdentifiers

// Define a selection of the UTI supertypes Apple defines (https://developer.apple.com/documentation/uniformtypeidentifiers/uttype-swift.struct)
// Convert raw values to kebab-case for friendleness
//
// General philosphy for types here, besides the requirement that they be conformance types,
// is that they are not made redudant by extensions. They need to be an umbrella type, or stand
// in for situations where you couldn't derive the type from the extension alone (makefile for example)
enum Supertypes: String, CaseIterable, ExpressibleByArgument {
	// Text & Documents
	case text = "text"
	case csv = "csv"
	case image = "image"
	case rawImage = "raw-image"

	// Audio & Video
	case audio = "audio"  // Base audio
	case video = "video"  // Base video (no audio)
	case movie = "movie"  // Base audiovisual
	case mpeg4Audio = "mp4-audio"
	case quicktime = "quicktime"
	case mpeg4Movie = "mp4-movie"

	// Archives
	case archive = "archive"

	// Source Code
	case source = "sourcecode"
	case cSource = "c-source"
	case cppSource = "cpp-source"
	case objcSource = "objc-source"
	case shell = "shell"
	case makefile = "makefile"

	// Filesystem & System
	case data = "data"
	case directory = "directory"
	case folder = "folder"
	case symbolicLink = "symlink"
	case executable = "executable"
	case unixExecutable = "unix-executable"
	case applicationBundle = "app-bundle"

	// Computed property to get the actual UTType
	var utType: UTType? {
		switch self {
		// Text & Documents
		case .text: return .text
		case .csv: return .commaSeparatedText  // Map to most common CSV UTI

		// Images
		case .image: return .image
		case .rawImage: return .rawImage

		// Audio & Video
		case .audio: return .audio
		case .video: return .video
		case .movie: return .movie
		case .mpeg4Audio: return .mpeg4Audio
		case .quicktime: return .quickTimeMovie
		case .mpeg4Movie: return .mpeg4Movie

		// Archives
		case .archive: return .archive

		// Source Code
		case .source: return .sourceCode
		case .cSource: return .cSource
		case .cppSource: return .cPlusPlusSource
		case .objcSource: return .objectiveCSource
		case .shell: return .shellScript
		case .makefile: return .makefile

		// Filesystem & System
		case .data: return .data
		case .directory: return .directory
		case .folder: return .folder
		case .symbolicLink: return .symbolicLink
		case .executable: return .executable
		case .unixExecutable: return .unixExecutable
		case .applicationBundle: return .applicationBundle

		// default: return nil
		}
	}
}
