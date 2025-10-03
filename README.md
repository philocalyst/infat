# Welcome to Infat

[![Rust Version](https://badgen.net/static/Rust/2024/orange)](https://swift.org)
[![Apple Platform](https://badgen.net/badge/icon/macOS%2013+?icon=apple&label)](https://developer.apple.com/macOS)

Infat is an ultra-powerful, macOS-native CLI tool for declaratively managing both file-type and URL-scheme associations. Avoid the hassle of navigating sub-menus to setup your default browser or image viewer, and the pain of doing that *every time* you get a new machine. Setup the rules once, and bask in your own ingenuity forevermore. Take back control, and bind your openers to whatever. You. Want. Override everything! Who's going to stop you?

---

## Summary

- List which apps open for a given file extension or URL scheme (Like when you double click a file in Finder)
- Set a default application for a file extension or URL scheme  
- Load associations from a TOML config (`[extensions]` `[types]` and `[schemes]` tables)  
- Verbose, scriptable, and ideal for power users and admins  

## Get Started

Get started by installing Infat — jump to the [Install](#install) section below.

## Tutorial

### 1. Getting association information

```shell
# Show the default app for .txt files and all registered apps
infat info --ext txt
```

### 2. Setting a Default Application
> [!TIP]
> These aren't strict extensions, for example, yml and yaml extensions share a common resolver.

```shell
# Use TextEdit for .md files
infat set TextEdit --ext md

# Use VSCode for .json files
infat set VSCode --ext json
```

### 3. Binding a URL Scheme

```shell
# Use Mail.app for mailto: links
infat set Mail --scheme mailto
```

### 4. Fallback types

> [!TIP]
> Openers are cascading in macOS. Most common file formats will have their own identifier,
> Which will be read from before the plain-text type it inherits from
> Try setting from extension if you face unexpected issues

```shell
# Set VSCode as the opener for files containing text
infat set VSCode --type plain-text
```

Infat currently supports these supertypes:

- plain-text
- text
- csv
- image
- raw-image
- audio
- video
- movie
- mp4-audio
- quicktime
- mp4-movie
- archive
- sourcecode
- c-source
- cpp-source
- objc-source
- shell
- makefile
- data
- directory
- folder
- symlink
- executable
- unix-executable
- app-bundle

### 5. Configuration

Place a TOML file at `$XDG_CONFIG_HOME/infat/config.toml` (or pass `--config path/to/config.toml`). 

> [!NOTE] 
> `$XDG_CONFIG_HOME` is not set by default, you need to set in your shell config ex: `.zshenv`.

On the right is the app you want to bind. You can pass:
1. The name (As seen when you hover on the icon) **IF** It's in a default location.
2. The relative path (To your user directory: ~)
3. The absolute path

All case sensitive, all can be with or without a .app suffix, and no shell expansions...

```toml
[extensions]
md    = "TextEdit"
html  = "Safari"
pdf   = "Preview"

[schemes]
mailto = "Mail"
web    = "Safari"

[types]
plain-text = "VSCode"
```

Run without arguments to apply all entries.

```shell
infat --config ~/.config/infat/config.toml
```

---

## Design Philosophy

- **Minimal & Scriptable**  
  Infat is a single-binary tool that plays well in shells and automation pipelines.

- **macOS-First**  
  Leverages native `NSWorkspace`, Launch Services, and UTType for robust integration.

- **Declarative Configuration**  
  TOML support allows you to version-control your associations alongside other dotfiles.

## Building and Debugging

You’ll need [just](https://github.com/casey/just) and the rust compiler for the build. If you want to be simple, install nix, and run `nix develop .`

```shell
# Debug build
just build

# Release build
just build-release

# Run in debug mode
just run "list txt"

# Enable verbose logging for troubleshooting
infat --verbose info --ext pdf
```

---

## Install

### Homebrew

```shell
brew update # Optional but recommended
brew install infat
```

### From Source

Please make sure `just` (our command-runner) is installed before running. If you don't want to use `just`, the project is managed with SPM, and you can build with "Swift build -c release" and move the result in the .build folder to wherever. 

```shell
git clone https://github.com/philocalyst/infat.git && cd infat
just package && mv dist/infat* /usr/local/bin/infat # Wildcard because output name includes platform
```

## Changelog

For the full history of changes, see [CHANGELOG.md](CHANGELOG.md).

## Libraries Used

- [clap](https://lib.rs/crates/clap)
- [Toml](https://lib.rs/crates/toml)
- [Serde](https://lib.rs/crates/serde)
- [thiserror](https://lib.rs/crates/thiserror)
- [eyre](https://lib.rs/crates/eyre)
- [color-eyre](https://lib.rs/crates/color-eyre)
- [tracing](https://lib.rs/crates/tracing)
- [tracing-subscriber](https://lib.rs/crates/tracing-subscriber)
- [core-foundation](https://lib.rs/crates/core-foundation)
- [core-services](https://lib.rs/crates/core-services)


## Acknowledgements

- Inspired by [duti](https://github.com/moretension/duti)  
- Built with Apple API's, thank you's to our corporate overlord Apple for not locking these capabilities away and instead just having poorly-documented error codes :)
- Thanks to all contributors and issue submitters, y'all rock and combat my lack of test-cases.. heh 

## License

Infat is licensed under the [MIT License](LICENSE).  
Feel free to use, modify, and distribute!
