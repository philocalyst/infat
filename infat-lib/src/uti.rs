// infat-lib/src/uti.rs - COMPLETE implementation
use crate::error::{InfatError, Result};
use serde::{Deserialize, Serialize};
use std::str::FromStr;

/// Standard UTI supertypes that infat recognizes
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum SuperType {
    // Text & Documents
    Text,
    PlainText,
    Csv,
    Json,
    Xml,
    Yaml,
    Html,
    Markdown,
    Rtf,

    // Images
    Image,
    RawImage,
    Png,
    Jpeg,
    Gif,
    Tiff,
    Svg,
    WebP,
    Heic,
    Heif,
    Bmp,

    // Audio
    Audio,
    Mp3,
    Wav,
    Aiff,
    Midi,
    Mp4Audio,
    AppleProtectedMp4Audio,
    Flac,
    OggAudio,
    Ac3Audio,
    AacAudio,

    // Video
    Video,
    Mpeg2TransportStream,
    Movie,
    QuicktimeMovie,
    Mp4Movie,
    AppleProtectedMp4Video,
    Mpeg,
    Mpeg2Video,
    Avi,
    DvMovie,
    RealMedia,
    RealAudio,
    Webm,
    Matroska,
    M3uPlaylist,

    // Archives
    Archive,
    Zip,
    Gzip,
    Tar,
    Bz2,
    AppleArchive,

    // Source Code
    Sourcecode,
    CSource,
    CHeader,
    CppSource,
    CppHeader,
    ObjcSource,
    ObjcPlusPlusSource,
    SwiftSource,
    Shell,
    Makefile,
    Javascript,
    PythonScript,
    RubyScript,
    PerlScript,
    PhpScript,
    AppleScript,
    AssemblySource,

    // System
    Data,
    Directory,
    Folder,
    Symlink,
    Executable,
    UnixExecutable,
    AppBundle,
    Framework,
    DiskImage,
    Volume,
    MountPoint,
    AliasFile,

    // 3D Content
    ThreeDContent,
    Usd,
    Usdz,
    RealityFile,
    SceneKitScene,

    // Fonts
    Font,

    // Cryptographic
    Pkcs12,
    X509Certificate,

    // URLs
    Url,
    FileUrl,
    UrlBookmarkData,

    // Property Lists
    PropertyList,
    XmlPropertyList,
    BinaryPropertyList,

    // Misc
    Log,
    Bookmark,
    InternetLocation,
    InternetShortcut,

    // Apple-specific
    DefaultAppWebBrowser,
    DefaultAppMailClient,
    M4vVideo,
    M4aAudio,
}

impl SuperType {
    /// Get the corresponding macOS UTI string
    pub fn uti_string(&self) -> &'static str {
        match self {
            Self::Text => "public.text",
            Self::PlainText => "public.plain-text",
            Self::Csv => "public.comma-separated-values-text",
            Self::Json => "public.json",
            Self::Xml => "public.xml",
            Self::Yaml => "public.yaml",
            Self::Html => "public.html",
            Self::Markdown => "net.daringfireball.markdown",
            Self::Rtf => "public.rtf",

            Self::Image => "public.image",
            Self::RawImage => "public.camera-raw-image",
            Self::Png => "public.png",
            Self::Jpeg => "public.jpeg",
            Self::Gif => "com.compuserve.gif",
            Self::Tiff => "public.tiff",
            Self::Svg => "public.svg-image",
            Self::WebP => "org.webmproject.webp",
            Self::Heic => "public.heic",
            Self::Heif => "public.heif",
            Self::Bmp => "com.microsoft.bmp",

            Self::Audio => "public.audio",
            Self::Mp3 => "public.mp3",
            Self::Wav => "com.microsoft.waveform-audio",
            Self::Aiff => "public.aiff-audio",
            Self::Midi => "public.midi-audio",
            Self::Mp4Audio => "public.mpeg-4-audio",
            Self::AppleProtectedMp4Audio => "com.apple.protected-mpeg-4-audio",
            Self::Flac => "org.xiph.flac",
            Self::OggAudio => "org.xiph.ogg-audio",
            Self::Ac3Audio => "public.ac3-audio",
            Self::AacAudio => "public.aac-audio",

            Self::Video => "public.video",
            Self::Movie => "public.movie",
            Self::QuicktimeMovie => "com.apple.quicktime-movie",
            Self::Mp4Movie => "public.mpeg-4",
            Self::AppleProtectedMp4Video => "com.apple.protected-mpeg-4-video",
            Self::Mpeg => "public.mpeg",
            Self::Mpeg2Video => "public.mpeg-2-video",
            Self::Avi => "public.avi",
            Self::DvMovie => "public.dv-movie",
            Self::RealMedia => "com.real.realmedia",
            Self::RealAudio => "com.real.realaudio",
            Self::Mpeg2TransportStream => "mpeg2-transport-stream",
            Self::Webm => "org.webmproject.webm",
            Self::M3uPlaylist => "m3u-playlist",
            Self::Matroska => "org.matroska.mkv",

            Self::Archive => "public.archive",
            Self::Zip => "public.zip-archive",
            Self::Gzip => "org.gnu.gnu-zip-archive",
            Self::Tar => "public.tar-archive",
            Self::Bz2 => "public.bzip2-archive",
            Self::AppleArchive => "com.apple.archive",

            Self::Sourcecode => "public.source-code",
            Self::CSource => "public.c-source",
            Self::CHeader => "public.c-header",
            Self::CppSource => "public.c-plus-plus-source",
            Self::CppHeader => "public.c-plus-plus-header",
            Self::ObjcSource => "public.objective-c-source",
            Self::ObjcPlusPlusSource => "public.objective-c-plus-plus-source",
            Self::SwiftSource => "public.swift-source",
            Self::Shell => "public.shell-script",
            Self::Makefile => "public.make-source",
            Self::Javascript => "com.netscape.javascript-source",
            Self::PythonScript => "public.python-script",
            Self::RubyScript => "public.ruby-script",
            Self::PerlScript => "public.perl-script",
            Self::PhpScript => "public.php-script",
            Self::AppleScript => "com.apple.applescript.text",
            Self::AssemblySource => "public.assembly-source",

            Self::Data => "public.data",
            Self::Directory => "public.directory",
            Self::Folder => "public.folder",
            Self::Symlink => "public.symlink",
            Self::Executable => "public.executable",
            Self::UnixExecutable => "public.unix-executable",
            Self::AppBundle => "com.apple.application-bundle",
            Self::Framework => "com.apple.framework",
            Self::DiskImage => "public.disk-image",
            Self::Volume => "public.volume",
            Self::MountPoint => "com.apple.mount-point",
            Self::AliasFile => "com.apple.alias-file",

            Self::ThreeDContent => "public.3d-content",
            Self::Usd => "com.pixar.universal-scene-description",
            Self::Usdz => "com.pixar.universal-scene-description-mobile",
            Self::RealityFile => "com.apple.reality",
            Self::SceneKitScene => "com.apple.scenekit.scene",

            Self::Font => "public.font",

            Self::Pkcs12 => "com.rsa.pkcs-12",
            Self::X509Certificate => "public.x509-certificate",

            Self::Url => "public.url",
            Self::FileUrl => "public.file-url",
            Self::UrlBookmarkData => "com.apple.bookmark",

            Self::PropertyList => "com.apple.property-list",
            Self::XmlPropertyList => "com.apple.xml-property-list",
            Self::BinaryPropertyList => "com.apple.binary-property-list",

            Self::Log => "public.log",
            Self::Bookmark => "public.bookmark",
            Self::InternetLocation => "com.apple.web-internet-location",
            Self::InternetShortcut => "com.microsoft.internet-shortcut",

            Self::DefaultAppWebBrowser => "com.apple.default-app.web-browser",
            Self::DefaultAppMailClient => "com.apple.default-app.mail-client",
            Self::M4vVideo => "com.apple.m4v-video",
            Self::M4aAudio => "com.apple.m4a-audio",
        }
    }

    /// Get all available supertypes
    pub fn all() -> Vec<SuperType> {
        vec![
            Self::Text,
            Self::PlainText,
            Self::Csv,
            Self::Json,
            Self::Xml,
            Self::Yaml,
            Self::M3uPlaylist,
            Self::Html,
            Self::Markdown,
            Self::Rtf,
            Self::Image,
            Self::RawImage,
            Self::Png,
            Self::Jpeg,
            Self::Gif,
            Self::Tiff,
            Self::Svg,
            Self::WebP,
            Self::Heic,
            Self::Heif,
            Self::Bmp,
            Self::Audio,
            Self::Mp3,
            Self::Wav,
            Self::Aiff,
            Self::Midi,
            Self::Mp4Audio,
            Self::AppleProtectedMp4Audio,
            Self::Flac,
            Self::OggAudio,
            Self::Ac3Audio,
            Self::AacAudio,
            Self::Video,
            Self::Movie,
            Self::QuicktimeMovie,
            Self::Mp4Movie,
            Self::AppleProtectedMp4Video,
            Self::Mpeg,
            Self::Mpeg2Video,
            Self::Avi,
            Self::DvMovie,
            Self::RealMedia,
            Self::RealAudio,
            Self::Webm,
            Self::Matroska,
            Self::Archive,
            Self::Zip,
            Self::Gzip,
            Self::Tar,
            Self::Bz2,
            Self::AppleArchive,
            Self::Sourcecode,
            Self::CSource,
            Self::CHeader,
            Self::CppSource,
            Self::CppHeader,
            Self::ObjcSource,
            Self::ObjcPlusPlusSource,
            Self::SwiftSource,
            Self::Shell,
            Self::Makefile,
            Self::Javascript,
            Self::PythonScript,
            Self::RubyScript,
            Self::PerlScript,
            Self::PhpScript,
            Self::AppleScript,
            Self::AssemblySource,
            Self::Data,
            Self::Directory,
            Self::Folder,
            Self::Symlink,
            Self::Executable,
            Self::UnixExecutable,
            Self::AppBundle,
            Self::Framework,
            Self::DiskImage,
            Self::Volume,
            Self::MountPoint,
            Self::AliasFile,
            Self::ThreeDContent,
            Self::Usd,
            Self::Usdz,
            Self::RealityFile,
            Self::SceneKitScene,
            Self::Font,
            Self::Pkcs12,
            Self::X509Certificate,
            Self::Url,
            Self::FileUrl,
            Self::UrlBookmarkData,
            Self::PropertyList,
            Self::Mpeg2TransportStream,
            Self::XmlPropertyList,
            Self::BinaryPropertyList,
            Self::Log,
            Self::Bookmark,
            Self::InternetLocation,
            Self::InternetShortcut,
            Self::DefaultAppWebBrowser,
            Self::DefaultAppMailClient,
            Self::M4vVideo,
            Self::M4aAudio,
        ]
    }

    /// Try to find a supertype by UTI string
    pub fn from_uti_string(uti: &str) -> Option<SuperType> {
        Self::all().into_iter().find(|st| st.uti_string() == uti)
    }
}

impl FromStr for SuperType {
    type Err = InfatError;

    fn from_str(s: &str) -> Result<Self> {
        let normalized = s.to_lowercase().replace('_', "-");

        match normalized.as_str() {
            "text" => Ok(Self::Text),
            "plain-text" => Ok(Self::PlainText),
            "csv" => Ok(Self::Csv),
            "json" => Ok(Self::Json),
            "xml" => Ok(Self::Xml),
            "yaml" => Ok(Self::Yaml),
            "html" => Ok(Self::Html),
            "markdown" => Ok(Self::Markdown),
            "rtf" => Ok(Self::Rtf),

            "image" => Ok(Self::Image),
            "raw-image" => Ok(Self::RawImage),
            "png" => Ok(Self::Png),
            "jpeg" => Ok(Self::Jpeg),
            "gif" => Ok(Self::Gif),
            "tiff" => Ok(Self::Tiff),
            "svg" => Ok(Self::Svg),
            "webp" => Ok(Self::WebP),
            "heic" => Ok(Self::Heic),
            "heif" => Ok(Self::Heif),
            "bmp" => Ok(Self::Bmp),

            "audio" => Ok(Self::Audio),
            "mp3" => Ok(Self::Mp3),
            "wav" => Ok(Self::Wav),
            "aiff" => Ok(Self::Aiff),
            "midi" => Ok(Self::Midi),
            "mp4-audio" => Ok(Self::Mp4Audio),

            "video" => Ok(Self::Video),
            "movie" => Ok(Self::Movie),
            "quicktime-movie" => Ok(Self::QuicktimeMovie),
            "mp4-movie" => Ok(Self::Mp4Movie),
            "mpeg" => Ok(Self::Mpeg),
            "avi" => Ok(Self::Avi),

            "csv" | "comma-separated-text" => Ok(Self::Csv),
            "mpeg2-video" => Ok(Self::Mpeg2Video),
            "mpeg2-transport-stream" => Ok(Self::Mpeg2TransportStream),
            "mpeg4-movie" => Ok(Self::Mp4Movie),
            "m3u" | "m3u-playlist" => Ok(Self::M3uPlaylist),

            "archive" => Ok(Self::Archive),
            "zip" => Ok(Self::Zip),
            "gzip" => Ok(Self::Gzip),
            "tar" => Ok(Self::Tar),

            "sourcecode" => Ok(Self::Sourcecode),
            "c-source" => Ok(Self::CSource),
            "cpp-source" => Ok(Self::CppSource),
            "objc-source" => Ok(Self::ObjcSource),
            "swift-source" => Ok(Self::SwiftSource),
            "shell" => Ok(Self::Shell),
            "makefile" => Ok(Self::Makefile),
            "javascript" => Ok(Self::Javascript),
            "python-script" => Ok(Self::PythonScript),

            "data" => Ok(Self::Data),
            "directory" => Ok(Self::Directory),
            "folder" => Ok(Self::Folder),
            "symlink" => Ok(Self::Symlink),
            "executable" => Ok(Self::Executable),
            "unix-executable" => Ok(Self::UnixExecutable),
            "app-bundle" => Ok(Self::AppBundle),

            _ => Err(InfatError::UnsupportedSupertype {
                name: s.to_string(),
            }),
        }
    }
}

impl std::fmt::Display for SuperType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let kebab_case = match self {
            Self::PlainText => "plain-text",
            Self::RawImage => "raw-image",
            Self::Mp4Audio => "mp4-audio",
            Self::AppleProtectedMp4Audio => "apple-protected-mp4-audio",
            Self::QuicktimeMovie => "quicktime-movie",
            Self::Mp4Movie => "mp4-movie",
            Self::AppleProtectedMp4Video => "apple-protected-mp4-video",
            Self::Mpeg2Video => "mpeg2-video",
            Self::DvMovie => "dv-movie",
            Self::AppleArchive => "apple-archive",
            Self::CSource => "c-source",
            Self::CHeader => "c-header",
            Self::CppSource => "cpp-source",
            Self::CppHeader => "cpp-header",
            Self::ObjcSource => "objc-source",
            Self::ObjcPlusPlusSource => "objc-plus-plus-source",
            Self::SwiftSource => "swift-source",
            Self::PythonScript => "python-script",
            Self::RubyScript => "ruby-script",
            Self::PerlScript => "perl-script",
            Self::PhpScript => "php-script",
            Self::AppleScript => "apple-script",
            Self::AssemblySource => "assembly-source",
            Self::UnixExecutable => "unix-executable",
            Self::AppBundle => "app-bundle",
            Self::DiskImage => "disk-image",
            Self::MountPoint => "mount-point",
            Self::AliasFile => "alias-file",
            Self::ThreeDContent => "3d-content",
            Self::RealityFile => "reality-file",
            Self::SceneKitScene => "scenekit-scene",
            Self::X509Certificate => "x509-certificate",
            Self::FileUrl => "file-url",
            Self::UrlBookmarkData => "url-bookmark-data",
            Self::PropertyList => "property-list",
            Self::XmlPropertyList => "xml-property-list",
            Self::BinaryPropertyList => "binary-property-list",
            Self::InternetLocation => "internet-location",
            Self::InternetShortcut => "internet-shortcut",
            Self::DefaultAppWebBrowser => "default-app-web-browser",
            Self::DefaultAppMailClient => "default-app-mail-client",
            Self::M4vVideo => "m4v-video",
            Self::M4aAudio => "m4a-audio",
            _ => {
                return write!(f, "{:?}", self)
                    .map(|_| ())
                    .map_err(|_| std::fmt::Error)
            }
        };

        write!(f, "{}", kebab_case.to_lowercase())
    }
}
