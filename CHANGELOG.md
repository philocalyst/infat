# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/philocalyst/infat/compare/d32aec000bf040c48887f104decf4a9736aea78b...HEAD
[0.3.0]: https://github.com/philocalyst/infat/compare/v0.2.0...v0.3.0  
[0.2.0]: https://github.com/philocalyst/infat/compare/63822faf94def58bf347f8be4983e62da90383bb...d32aec000bf040c48887f104decf4a9736aea78b (Comparing agaisnt the start of the project)
