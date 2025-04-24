# Welcome to Infat

Infat is a powerful, macOS-native CLI tool for managing both file-type and URL-scheme associations declaritively. Bind your openers in weird and undefined ways! MacOS doesn't care, honestly.

---

## Summary

- List which apps open a given file extension or URL scheme  
- Set a default application for a file extension or URL scheme  
- Load associations from a TOML config (`[files]` and `[schemes]` tables)  
- Verbose, scriptable, and ideal for power users and admins  

---

## Get Started

Get started by installing Infat — jump to the [Install](#install) section below.

---

## Tutorial

### 1. Listing Associations

```bash
# Show the default app for .txt files
infat list txt

# Show all registered apps for .txt files
infat list --assigned txt
```

### 2. Setting a Default Application

```bash
# Use TextEdit for .md files
infat set TextEdit --file-type md

# Use VSCode for .json files
infat set VSCode --file-type json
```

### 3. Binding a URL Scheme

```bash
# Use Mail.app for mailto: links
infat set Mail --scheme mailto
```

### 4. Configuration

Place a TOML file at `$XDG_CONFIG_HOME/infat/config.toml` (or pass `--config path/to/config.toml`) with two tables:

```toml
[files]
md    = "TextEdit"
html  = "Safari"
pdf   = "Preview"

[schemes]
mailto = "Mail"
web    = "Safari"
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

---

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
infat --verbose list pdf
```

---

## Install

### Homebrew

```bash
brew install philocalyst/tap/infat
```

### From Source

```bash
git clone https://github.com/philocalyst/infat.git
cd infat
just build-release
cp .build/release/infat /usr/local/bin/infat
```

---

## Changelog

For the full history of changes, see [CHANGELOG.md](CHANGELOG.md).

---

## Libraries Used

- [ArgumentParser](https://github.com/apple/swift-argument-parser)  
- [swift-log](https://github.com/apple/swift-log)  
- [PListKit](https://github.com/orchetect/PListKit)  
- [swift-toml](https://github.com/jdfergason/swift-toml)  

---

## Acknowledgements

- Inspired by [duti](https://github.com/moretension/duti)  
- Built with Swift, thanks to corporate overlord Apple’s frameworks  
- Thanks to all contributors and issue submitters (One day!!)

---

## License

Infat is licensed under the [MIT License](LICENSE).  
Feel free to use, modify, and distribute!
