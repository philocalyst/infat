#!/usr/bin/env just
set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := true
set allow-duplicate-recipes := true

# --- Variables --- #
project_root := justfile_directory()
output_directory := project_root / "dist" # The output artifacts lie here

current_platform := `uname -m` + "-apple-" + os() # The tuple that swift expects

default_bin := "infat" # The main artifact of the project
build_dir := project_root / ".build" # Where the building artifcats are stored
debug_bin := build_dir / "debug" / default_bin
release_bin := build_dir / "release" / default_bin

[doc('List the project (default action)')]
default:
    @just --list

[doc('Build Swift package in debug mode')]
[group('build')]
build target=(current_platform):
    @echo "🔨 Building Swift package (debug)…"
    swift build --triple {{target}}

[doc('Build Swift package in release mode')]
[group('build')]
build-release target=(current_platform):
    @echo "🚀 Building Swift package (release)…"
    swift build -c release -Xswiftc "-whole-module-optimization" --triple {{target}} -Xlinker "-dead_strip"

[doc('Finalize release binary')]
[group('packaging')]
package target=(current_platform) result_directory=(output_directory):
    just build-release {{target}}
    @echo "📦 Packaging release binary…"
    @mkdir -p {{output_directory}}
    @cp {{release_bin}} "{{result_directory}}/{{default_bin}}-{{target}}"
    @echo "✅ Packaged → {{result_directory}}/{{default_bin}}-{{target}}"

[doc('Compress binary files in target directory')]
[group('packaging')]
compress-binaries target_directory=("."):
    #!/usr/bin/env bash

    find "${target_directory}" -maxdepth 1 -type f -print0 | while IFS= read -r -d $'\0' file; do
    # Check if the file command output indicates a binary/executable type
    if file "$file" | grep -q -E 'executable|ELF|Mach-O|shared object'; then
        # Get the base filename without the path
        filename=$(basename "$file")

        # Get the base name without version number
        basename="${filename%%-*}"

        echo "Archiving binary file: $filename"

        # Create archive with just the basename, no directory structure
        tar -czf "${file}.tar.gz" \
            -C "$(dirname "$file")" \
            -s "|^${filename}$|${basename}|" \
            "$(basename "$file")"
    fi
    done

[doc('Generate SHA256 checksums for files in a directory')]
[group('packaging')]
checksum directory=(output_directory):
    @echo "🔒 Creating checksums in {{directory}}…"
    @find "{{directory}}" -type f \
        ! -name "checksums.sha256" \
        ! -name "*.sha256" \
        -exec sh -c 'sha256sum "$1" > "$1.sha256"' _ {} \;
    @echo "✅ Checksums created!"

[doc('Run the application in debug mode')]
[group('execution')]
run +args="":
    @echo "▶️ Running (debug)…"
    swift run {{default_bin}} {{args}}

[doc('Run the application in release mode')]
[group('execution')]
run-release +args="":
    @echo "▶️ Running (release)…"
    swift run -c release -Xswiftc "-whole-module-optimization" {{release_bin}} {{args}}

[doc('Build and install the binary to /usr/local/bin')]
[group('installation')]
install: build-release
    @echo "💾 Installing {{default_bin}} → /usr/local/bin…"
    @cp {{release_bin}} /usr/local/bin/{{default_bin}}

[doc('Force install the binary')]
[group('installation')]
install-force: build-release
    @echo "💾 Force installing {{default_bin}} → /usr/local/bin…"
    @cp {{release_bin}} /usr/local/bin/{{default_bin}} --force

[doc('Extract release notes from changelog for specified tag')]
[group('maintenance')]
create-notes raw_tag outfile changelog:
    #!/usr/bin/env bash

    tag_v="${raw_tag}"
    tag="${tag_v#v}" # Remove prefix v

    # Changes header for release notes
    printf "# What's new\n" > "{{outfile}}"

    if [[ ! -f "{{changelog}}" ]]; then
      echo "Error: {{changelog}} not found." >&2
      exit 1
    fi

    echo "Extracting notes for tag: {{raw_tag}} (searching for section [$tag])"
    # Use awk to extract the relevant section from the changelog
    awk -v tag="$tag" '
      # start printing when we see "## [<tag>]" (escape brackets for regex)
      $0 ~ ("^## \\[" tag "\\]") { printing = 1; next }
      # stop as soon as we hit the next "## [" section header
      printing && /^## \[/       { exit }
      # otherwise, if printing is enabled, print the current line
      printing                    { print }

      # Error handling
      END {
        if (found_section != 0) {
          # Print error to stderr
          print "Error: awk could not find section header ## [" tag "] in " changelog_file > "/dev/stderr"
          exit 1
        }
      }
    ' "{{changelog}}" >> "{{outfile}}"

    # Check if the output file has content
    if [[ -s {{outfile}} ]]; then
      echo "Successfully extracted release notes to '{{outfile}}'."
    else
      # Output a warning if no notes were found for the tag
      echo "Warning: '{{outfile}}' is empty. Is '## [$tag]' present in '{{changelog}}'?" >&2
    fi

[doc('Format all Swift source files')]
[group('maintenance')]
format:
    find . -name "*.swift" -type f -exec swift-format format -i {} +

[doc('Clean artifacts and resolve dependencies')]
[group('maintenance')]
clean:
    @echo "🧹 Cleaning build artifacts…"
    swift package clean
    swift package resolve
    
[doc('Update Swift package dependencies')]
[group('maintenance')]
update:
    @echo "🔄 Updating Swift package dependencies…"
    swift package update

# --- Aliases --- #
alias b := build
alias br := build-release
alias p := package
alias cb := compress-binaries
alias ch := checksum
alias r := run
alias f := format
alias rr := run-release
alias cl := clean
alias i := install
alias ifo := install-force
alias up := update
