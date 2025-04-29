# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.3.3] – 2025-04-29

### Added
- Support XDG Base Directory spec for configuration file search: respect  
  `XDG_CONFIG_HOME` (default `~/.config/infat/config.toml`) and  
  `XDG_CONFIG_DIRS` (default `/etc/xdg/infat/config.toml`).
- Add a GitHub Actions **homebrew** job to automatically bump the Homebrew  
  formula on tagged releases.

### Changed
- Refactor Zsh, Bash and Fish completion scripts to use the official file-type  
  list and improve argument parsing.
- Update README:
  - Change Homebrew installation to `brew install infat`.
  - Add instructions for manual generation of shell completions until the formula  
    supports them.
- Update `.github/workflows/release.yml` to integrate the Homebrew bump step.

### Fixed
- Correct README misdocumentation by updating the list of supported file supertypes.

## [2.3.2] – 2025-04-27

### Fixed
- Set `overwrite: true` in the GitHub Actions release workflow to ensure existing releases can be replaced.
- Refine the `just check` recipe to ignore `CHANGELOG*`, `README*`, `Package*` files and the `.build` directory when scanning for version patterns.
- Update the `compress-binaries` recipe in Justfile so that archives
  - strip version suffixes from file names  
  - use only the base filename when creating the `.tar.gz`  

## [2.3.1] – 2025-04-27

### Changed
- Print success messages in italic formatting for `infat set` commands (file, scheme, and supertype bindings).
- Clarify README instructions: allow user-relative paths via `~` and note that shell expansions are not supported.

### Fixed
- Remove duplicate `run` step in the GitHub Actions `release.yml` workflow.

## [2.3.0] – 2025-04-27

### Added
- compress-binaries: use the project’s `infat` name to create `.tar.gz` archives with un-versioned internal filenames  
- AssociationManager: support relative paths (tilde expansion) and file:// URLs in `findApplication(named:)`

### Changed
- restyled `justfile` with decorative section markers and switched to `/`-based path concatenation for clarity

### Fixed
- release workflow: replaced `overwrite: true` with `make_latest: true` to correctly mark the latest GitHub release  
- prerelease check in Actions: now properly detects `-alpha` and `-beta` tags

## [2.2.0] – 2025-04-26

### Added
- Introduce ColorizeSwift (v1.5.0) as a new dependency for rich terminal styling  
- Reroute `.html` file‐extension and `https` URL‐scheme inputs to the HTTP handler  
- Support colorized output styling via `.bold()` and `.underline()` in `ConfigManager`

### Changed
- Replace custom ANSI escape‐sequence constants with ColorizeSwift’s `.bold()` and `.underline()` methods  
- Docs updates:
  - Clarify application name casing and optional `.app` suffix in README  
  - Expand configuration section to cover three TOML tables and XDG_CONFIG_HOME usage  
  - Correct CLI usage examples, header numbering, typos, and outdated information  

## [2.1.0] – 2025-04-26

### Added
- Justfile  
  Introduce a `check` task that prompts you to confirm version bumps in the README, Swift bundle and CHANGELOG.
- Commands  
  Print a success message when an application is bound to a file extension or URL scheme.
- FileSystemUtilities  
  Include `/System/Library/CoreServices/Applications/` in the list of search paths for installed apps.
- AssociationManager  
  Add a fallback for `setDefaultApplication` failures: if `NSWorkspace.setDefaultApplication` is restricted, catch the error and invoke `LSSetDefaultRoleHandlerForContentType` directly.

### Changed
- Package.swift  
  Pin all external Swift package dependencies to exact versions (ArgumentParser 1.2.0, Swift-Log 1.5.3, PListKit 2.0.3, swift-toml 1.0.0).
- AssociationManager  
  Refactor application lookup into a throwing `findApplication(named:)`, supporting both file paths (or file:// URLs) and plain `.app` names (case-insensitive).
- FileSystemUtilities  
  Downgrade log level for unreadable paths from **warning** to **debug** to reduce noise.

## [2.0.1] – 2025-04-25

### Added
- Support for cascading “blanket” types: use `infat set <App> --type <type>` to
  assign openers for base types (e.g. `plain-text`); introduced a new
  `[types]` table in the TOML schema.
- Explicit handling when no config is provided or found: Infat now prints
  an informative prompt and throws `InfatError.missingOption` if neither
  `--config` nor `$XDG_CONFIG_HOME/infat/config.toml` exist.

### Changed
- Bumped CLI version to **2.0.1** and updated the abstract to
  “Declaritively set associations for URLs and files.”
- Revised README examples and docs:
  - Renamed `infat list` → `infat info`
  - Changed flag `--file-type` → `--ext`
  - Renumbered tutorial steps and cleaned up formatting
  - Updated TOML example: `[files]` → `[extensions]`

### Fixed
- Quiet mode now logs at `warning` (was `error`), preventing silent failures.

## [2.0.0] – 2025-04-25

### Added
- Enforce that exactly one of `--scheme`, `--type`, or `--ext` is provided in both the Info and Set commands; throw clear errors when options are missing or conflicting.  
- Introduce a new `--type` option to the Info command, allowing users to list both the default and all registered applications for a given supertype (e.g. `text`).  
- Add the `plain-text` supertype (mapped to `UTType.plainText`) to the set of supported conformances.  
- Render configuration section headings (`[extensions]`, `[types]`, `[schemes]`) in bold & underlined text when processing TOML files.

### Changed
- Require at least one of the `[extensions]`, `[types]`, or `[schemes]` tables in the TOML configuration (instead of mandating all); process each table if present, emit a debug-level log when a table is missing, and standardize table naming.  
- Change the default logging level for verbose mode from `debug` to `trace`.  
- Strengthen error handling in `_setDefaultApplication`: after attempting to set a default opener, verify success and log an info on success or a warning on failure.

### Deprecated
- Rename the `List` command to `Info`. 
- Renamed files table to extensions to match with cli options

## [1.3.0] – 2025-04-25

### Added
- `--app` option to `infat list` for listing document types handled by a given application.  
- New `InfatError.conflictingOptions` to enforce that exactly one of `--app` or `--ext` is provided.  
- Enhanced UTI-derivation errors via `InfatError.couldNotDeriveUTI`, including the offending extension in the message.

### Changed
- Refactored the `list` command to use two exclusive `@Option` parameters (`--app`, `--ext`) with XOR validation.  
- Switched PList parsing to `DictionaryPList(url:)` and UTI lookup to `UTType(filenameExtension:)`.  
- Replaced ad-hoc `print` calls with `logger.info` for consistent, leveled logging.  
- Renamed `deriveUTIFromExtension(extention:)` to `deriveUTIFromExtension(ext:)` for clarity and consistency.

### Fixed
- Corrected typos in `FileSystemUtilities.deriveUTIFromExtension` signature and related debug messages.  
- Fixed `FileManager` existence checks for `Info.plist` by using the correct `path` property.  
- Resolved parsing discrepancies in `listTypesForApp` to ensure accurate reading of `CFBundleDocumentTypes`.

## [1.2.0] – 2025-04-25

### Fixed
- Swift badge reflects true version

### Changed
- Using function overloading to set default application based on Uttype or extension

### Deprecated
- Removed --assocations option in list into the basic list command
- Filetype option, now ext.

### Added
- A supertype conformance enum
- Class option in CLI and Config

## [1.1.0] – 2025-04-24

### Added
- Add MIT License (`LICENSE`) under the MIT terms.
- Justfile enhancements:
  - Require `just` (command-runner) in documentation.
  - Introduce a `package` recipe (`just package`) to build and bundle release binaries.
  - Detect `current_platform` dynamically via `uname -m`.
- GitHub Actions release workflow: enable `overwrite: true` in `release.yml`.

### Changed
- Migrate `setDefaultApplication` and `ConfigManager.loadConfig` to async/await; remove semaphore-based callbacks.
- Simplify UTI resolution by passing `typeIdentifier` directly.
- Documentation updates:
  - Clarify README summary and usage examples for file-type and URL-scheme associations.
  - Revamp badges and stylistic copy (“ultra-powerful” intro, more user-friendly tone).
  - Streamline source installation instructions (use `just package` and wildcard install).

### Fixed
- Remove redundant separators in README.

## [1.0.0] - 2025-04-24

### Added
- Support for URL‐scheme associations in the `set` command via a new `--scheme` option  
- `InfatError.conflictingOptions` error case to enforce mutual exclusion of `--file-type` and `--scheme`  
- Unified binding functionality—`set` now handles both file‐type and URL‐scheme associations, replacing the standalone `bind` command  

### Changed
- Merged the former `bind` subcommand into `set` and switched its parameters from positional arguments to named options  
- Updated the `justfile` changelog target to use a top‐level `# What's new` header instead of `## Changes`  

### Removed
- Removed the standalone `Bind` subcommand and its `Bind.swift` implementation  
- Removed the `Info` subcommand (and `Info.swift`), which previously displayed system information  

## [0.6.0] - 2025-04-24

### Added
* Homebrew support

## [0.5.3] - 2025-04-24

### Fixed
* Typos in CI

## [0.5.2] - 2025-04-24

### Fixed
* Justfile platform targeting for the CI

## [0.5.1] - 2025-04-24

### Fixed
* Fixed logging to print diff in List command.
* Fixed Swift version in release workflow to a specific version instead of 'latest'.

## [0.5.0] – 2025-04-24

### Fixed
* Wrong swift toolchain action

## [0.4.0] – 2025-04-24

### Added
* Config support for schemes
* Bind subcommand to set URL scheme associations
* GitHub workflow for automated releases
* `create-notes` just recipe to extract changelog entries for release notes

### Changed
* Moved app name resolution logic to a function for better reusability
* Changed argument order in `setURLHandler` function
* Optimized Swift release flags for better performance
* Updated changelog to reflect the current state of the project

### Deprecated
* Associations table in config; it has been replaced by separate tables for files and schemes

### Fixed
* Logic in the Bind command to correctly handle application URL resolution and error handling

## [0.3.0] – 2025-04-23

### Added
- Support loading configuration from the XDG config directory (`$XDG_CONFIG_HOME/infat/config.toml`) when no `--config` flag is supplied.  
- Add a `Justfile` with curated recipes for:
  - building (debug / release)  
  - running (debug / release)  
  - packaging and compressing binaries  
  - generating checksums  
  - installing (and force-installing)  
  - cleaning and updating dependencies  

## [0.2.0] - 2025-04-22

### Added
- Initial project setup with basic command structure (`list`, `set`, `info`) using `swift-argument-parser`.
- Structured logging using `swift-log`.
- Custom error handling via the `InfatError` enum for specific error conditions.
- Defined `FileUTIInfo` struct for holding Uniform Type Identifier data.
- Added utility `findApplications` to locate application bundles in standard macOS directories.
- Added utility `deriveUTIFromExtension` to get UTI info from file extensions, requiring macOS 11.0+.
- Added utility `getBundleName` to extract bundle identifiers from application `Info.plist`.
- Implemented `list` subcommand to show default or all registered applications for a file type, using the logger for output.
- Implemented `set` subcommand to associate a file type with a specified application.
- Implemented `info` subcommand to display details about the current frontmost application.
- Added support for loading file associations from a TOML configuration file (`--config`), including specific error handling for TOML format issues and correcting an initial table name typo ("associations").
- Added dependencies: `PListKit` (for `Info.plist` parsing) and `swift-toml` (for configuration file parsing).
- Added shell completion scripts for Zsh, Bash, and Fish.
- Added comprehensive `README.md` documentation detailing features, usage, installation, and dependencies, with corrected links.

### Changed
- Renamed project, executable target, and main command struct from "bart"/"WorkspaceTool" to "infat".
- Refactored codebase from a single `main.swift` into multiple files (`Commands`, `Utilities`, `Managers`, `Error`, etc.) for better organization and readability.
- Updated the tool's abstract description for better clarity.
- Improved the output formatting of the `list` command for enhanced readability.
- Refactored `list` command options (using `--assigned` flag instead of `--all`, requiring identifier argument) and improved help descriptions.
- Consolidated logging flags: replaced previous `--debug` and `--verbose` flags with a single `--verbose` flag (which includes debug level) and a `--quiet` flag for minimal output.
- Made the global logger instance mutable (`var`) to allow runtime log level configuration based on flags.
- Created a reusable `setDefaultApplication` function to avoid code duplication between the `set` command and configuration loading logic.
- Significantly enhanced error handling with more specific `InfatError` cases (e.g., plist reading, timeout, configuration errors) and improved logging messages throughout the application.
- Implemented a 10-second timeout for the asynchronous `setDefaultApplication` operation using `DispatchSemaphore`.
- Updated `findApplications` utility to search `/System/Applications` in addition to other standard paths and use modern Swift API for home directory path resolution.
- Switched from using UTI strings to `UTType` objects within `FileUTIInfo` and related functions for better type safety and access to UTI properties.
- Updated `README.md` content, added TOML configuration documentation, and noted `set` command status (reflecting commit `1ec6358`).
- Set the minimum required macOS deployment target to 13.0 in `Package.swift`.
- Renamed the `set` command argument from `mimeType` to `fileType` for clarity.
- Updated the main command struct (`Infat`) and removed the redundant explicit `--version` flag (ArgumentParser provides this by default).
- Added `Package.resolved` to `.gitignore`.

### Fixed
- Corrected the bundle ID used internally and for logging from `com.example.burt` to `com.philocalyst.infat`.
- Addressed minor code formatting inconsistencies across several files.

[Unreleased]: https://github.com/your-org/your-repo/compare/v2.3.3...HEAD
[2.3.3]: https://github.com/philocalyst/infat/compare/v2.3.2...v2.3.3  
[2.3.2]: https://github.com/your-org/your-repo/compare/v2.3.1...v2.3.2
[2.3.1]: https://github.com/your-org/your-repo/compare/v2.3.0...v2.3.1
[2.3.0]: https://github.com/your-org/your-repo/compare/v2.2.0...v2.3.0
[2.2.0]:     https://github.com/philocalyst/infat/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/your-org/your-repo/compare/v2.0.1...v2.1.0  
[2.0.1]: https://github.com/philocalyst/infat/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/yourorg/yourrepo/compare/v1.3.0...v2.0.0  
[1.3.0]: https://github.com/your-org/infat/compare/v1.2.0...v1.3.0  
[1.2.0]: https://github.com/philocalyst/infat/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/philocalyst/infat/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/philocalyst/infat/compare/v0.6.0...v1.0.0 
[0.6.0]: https://github.com/philocalyst/infat/compare/v0.5.3...v0.6.0
[0.5.3]: https://github.com/philocalyst/infat/compare/v0.5.2...v0.5.3
[0.5.2]: https://github.com/philocalyst/infat/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/philocalyst/infat/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/philocalyst/infat/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/philocalyst/infat/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/philocalyst/infat/compare/v0.2.0...v0.3.0  
[0.2.0]: https://github.com/philocalyst/infat/compare/63822faf94def58bf347f8be4983e62da90383bb...d32aec000bf040c48887f104decf4a9736aea78b (Comparing agaisnt the start of the project)
