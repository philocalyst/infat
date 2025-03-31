
# Infat

A powerful CLI tool for managing file type associations on macOS. Infat provides a simple and elegant way to view, set, and manage file type associations through NSWorkspace.

Infat is designed for power users and system administrators who need fine-grained control over file associations. It offers a streamlined interface for managing which applications open which file types.

## Features

- **List file type associations** - See which applications are registered to open specific file types
- **Set default applications** - Change which application opens a specific file type
- **View system information** - Display useful information about the current system state
- **Standardized TOML Configuration** - Maintain a config file for versioning and the like (XDG support soon!)
- **Comprehensive logging** -  Verbose logging options for troubleshooting

## Installation

```bash
# Installation instructions coming soon
# For now, clone the repository and build from source
git clone https://github.com/philocalyst/infat.git
cd infat
swift build -c release
```

## Coming Soon

- **Support for early MacOS** - Should be able to get it dated to OSX initial release!
- **Batch operations** - Set multiple file associations at once
- **More detailed info commands** - Extended system information reporting

> **Note:** The info subcommand is not fully implemented yet but is coming in future releases! Any help is appreciated :)

## Tutorial

Infat follows a simple command structure with three main subcommands: `list`, `set`, and `info`.

### List Command

The `list` command shows which applications are registered to open specific file types.

```bash
# Show the default application for opening .txt files
infat list txt

# Show all applications registered to open .txt files
infat list --all txt
```

### Set Command


The `set` command changes which application opens a specific file type.

```bash
# Set TextEdit as the default application for .md files
infat set TextEdit md

# Set VSCode as the default application for .json files
infat set VSCode json
```

### Info Command

The `info` command displays system information, such as the currently active application.

Not implemented yet.

```bash
# Show system information
infat info
```


### Configuration

Create a TOML file with a table "associations"

And add assocations in this format:

EXTENSION = "APP"

Example:
```Toml
[associations]
toml = "Preview"
```

## Examples

Here are some common use cases for Infat:

### Change PDF viewer

```bash
# Set PDF files to open with Preview instead of Adobe Acrobat
infat set Preview pdf
```

### Fix broken file associations

```bash
# Reset .html files to open with Safari
infat set Safari html
```

### Check current associations

```bash
# Check which application is set to open .mp4 files
infat list mp4
```

## Debugging

Since Infat manipulates system settings, debugging can sometimes be necessary. Use the verbose and debug flags for more information:

```bash
# Enable verbose logging
infat --verbose set TextEdit txt

# Enable debug logging (even more verbose)
infat --debug list pdf
```

## Libraries used by Infat

- [ArgumentParser](https://github.com/apple/swift-argument-parser) - Command-line interface parsing
- [PListKit](https://github.com/hhas/Swift-PListKit) - Property list handling
- [Toml](https://github.com/jdfergason/swift-toml) - TOML configuration file parsing
- [Logging](https://github.com/apple/swift-log) - Structured logging

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

[MIT](LICENSE)

Made with massive inspiration of Duti https://github.com/moretension/duti, which is effective on earlier versions of macOS even now!

---

Made under duress by Miles :)
