# -*- mode: justfile -*-

set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := true
set allow-duplicate-recipes := true

# ===== Variables =====
project_root     := justfile_directory()
output_directory := project_root + "/dist"
default_bin      := "infat"
build_dir        := project_root + "/.build"
debug_bin        := build_dir + "/debug/{{default_bin}}"
release_bin      := build_dir + "/release/{{default_bin}}"

# ===== Default =====
default: build

# ===== Build & Check =====
build target="arm64-apple-macos":
	@echo "🔨 Building Swift package (debug)…"
	swift build --triple {{target}}

build-release target="arm64-apple-macos":
	@echo "🚀 Building Swift package (release)…"
	swift build -c release -Xswiftc "-whole-module-optimization" --triple {{target}} -Xlinker "-dead_strip"

# ===== Packaging =====
package: build-release
	@echo "📦 Packaging release binary…"
	@mkdir -p {{output_directory}}
	@cp {{release_bin}} {{output_directory}}/{{default_bin}}
	@echo "✅ Packaged → {{output_directory}}/{{default_bin}}"

compress-binaries target_directory=("."):
    #!/usr/bin/env bash
    
    find "{{target_directory}}" -maxdepth 1 -type f -print0 | while IFS= read -r -d $'\0' file; do

    # Check if the file command output indicates a binary/executable type
    if file "$file" | grep -q -E 'executable|ELF|Mach-O|shared object'; then
        # Get the base filename without the prepending components
        filename=$(basename "$file")
        echo "Archiving binary file: $filename"
        # Create a compressed tar archive named after the original file
        tar -czvf "${file}.tar.gz" "$file"
    fi
    done



checksum directory=(output_directory):
	@echo "🔒 Creating checksums in {{directory}}…"
	@find "{{directory}}" -type f \
	    ! -name "checksums.sha256" \
	    ! -name "*.sha256" \
	    -exec sh -c 'sha256sum "$1" > "$1.sha256"' _ {} \;
	@echo "✅ Checksums created!"

create-notes raw_tag outfile changelog:
    #!/usr/bin/env bash
    
    tag_v="{{raw_tag}}"
    tag="${tag_v#v}" # Remove prefix v

    # Changes header for release notes
    printf "## Changes\n" > "{{outfile}}"

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


# ===== Run =====
run +args="":
	@echo "▶️ Running (debug)…"
	swift run {{default_bin}} {{args}}

run-release +args="":
	@echo "▶️ Running (release)…"
	swift run -c release -Xswiftc "-whole-module-optimization" {{release_bin}} {{args}}

# ===== Cleaning =====
clean:
	@echo "🧹 Cleaning build artifacts…"
	swift package clean
	swift package resolve

# ===== Installation & Update =====
install: build-release
	@echo "💾 Installing {{default_bin}} → /usr/local/bin…"
	@cp {{release_bin}} /usr/local/bin/{{default_bin}}

install-force: build-release
	@echo "💾 Force installing {{default_bin}} → /usr/local/bin…"
	@cp {{release_bin}} /usr/local/bin/{{default_bin}} --force

update:
	@echo "🔄 Updating Swift package dependencies…"
	swift package update

# ===== Aliases =====
alias b   := build
alias br  := build-release
alias p   := package
alias cb  := compress-binaries
alias ch  := checksum
alias r   := run
alias rr  := run-release
alias cl  := clean
alias i   := install
alias ifo := install-force
alias up  := update
