# Welcome to Infat

[![Swift Version](https://badgen.net/static/Swift/5.9/orange)](https://swift.org)
[![Apple Platform](https://badgen.net/badge/icon/macOS%2013+?icon=apple&label)](https://developer.apple.com/macOS)

Infat is an ultra-powerful, macOS-native CLI tool for declaritively managing both file-type and URL-scheme associations. Avoid the hassle of navigating sub-menus to setup your default browser or image viewer, and the pain of doing that *every time* you get a new machine. Setup the rules once, and bask in your own ingenuity forevermore. Take back control, and bind your openers to whatever. You. Want. Override everything! Who's going to stop you?

---

## Summary

- List which apps open for a given file extension or URL scheme (Like when you double click a file in Finder)
- Set a default application for a file extension or URL scheme  
- Load associations from a TOML config (`[extensions]` `[types]` and `[schemes]` tables)  
- Verbose, scriptable, and ideal for power users and admins  

## Get Started

Get started by installing Infat — jump to the [Install](#install) section below.

## Tutorial

### 1. Getting assocation information

```bash
# Show the default app for .txt files and all registered apps
infat info txt
```

### 2. Setting a Default Application
> [!TIP]
> These aren't strict extensions, for example, yml and yaml extensions share a common resolver.

```bash
# Use TextEdit for .md files
infat set TextEdit --ext md

# Use VSCode for .json files
infat set VSCode --ext json
```

### 3. Binding a URL Scheme

```bash
# Use Mail.app for mailto: links
infat set Mail --scheme mailto
```

### 4. Blanket types

> [!TIP]
> Openers are cascading in macOS. Most common file formats will have their own identifier,
> Which will be read from before the plain-text type it inherits from
> Try setting from extension if you face unexpected issues

```shell
# Set VSCode as the opener for files containing text
infat set VSCode --type plain-text
```


### 4. Configuration

Place a TOML file at `$XDG_CONFIG_HOME/infat/config.toml` (or pass `--config path/to/config.toml`) with two tables:

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

```bash
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

You’ll need [just](https://github.com/casey/just) and Swift 5.9+:

```bash
# Debug build
just build

# Release build
just build-release

# Run in debug mode
just run "list txt"

# Enable verbose logging for troubleshooting
infat --verbose info pdf
```

---

## Install

### Homebrew

```bash
brew install philocalyst/tap/infat
```

### From Source

Please make sure just (Our command-runner) is installed before running. If you don't want to use just, the project is managed with SPM, and you can build with "Swift build -c release" and move the result in the .build folder to wherever. 
```bash
git clone https://github.com/philocalyst/infat.git && cd infat
just package && mv dist/infat* /usr/local/bin/infat # Wildcard because output name includes platform
```

## Changelog

For the full history of changes, see [CHANGELOG.md](CHANGELOG.md).

## Libraries Used

- [ArgumentParser](https://github.com/apple/swift-argument-parser)  
- [swift-log](https://github.com/apple/swift-log)  
- [PListKit](https://github.com/orchetect/PListKit)  
- [swift-toml](https://github.com/jdfergason/swift-toml)  

## Acknowledgements

- Inspired by [duti](https://github.com/moretension/duti)  
- Built with Swift, thanks to corporate overlord Apple’s frameworks  
- Thanks to all contributors and issue submitters (One day!!)

## License

Infat is licensed under the [MIT License](LICENSE).  
Feel free to use, modify, and distribute!
