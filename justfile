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
build:
	@echo "🔨 Building Swift package (debug)…"
	swift build

build-release:
	@echo "🚀 Building Swift package (release)…"
	swift build -c release

# ===== Packaging =====
package: build-release
	@echo "📦 Packaging release binary…"
	@mkdir -p {{output_directory}}
	@cp {{release_bin}} {{output_directory}}/{{default_bin}}
	@echo "✅ Packaged → {{output_directory}}/{{default_bin}}"

compress-binaries target_directory=("."):
	@echo "🗜 Compressing binaries in {{target_directory}}…"
	@find "{{target_directory}}" -maxdepth 1 -type f -executable \
		-print0 | \
	  xargs -0 -I {} bash -c ' \
	    if file "{}" | grep -qE "Mach-O.*executable"; then \
	      tar -czvf "{}.tar.gz" "{}"; \
	    fi \
	  '

checksum directory=(output_directory):
	@echo "🔒 Creating checksums in {{directory}}…"
	@find "{{directory}}" -type f \
	    ! -name "checksums.sha256" \
	    ! -name "*.sha256" \
	    -exec sh -c 'sha256sum "$1" > "$1.sha256"' _ {} \;
	@echo "✅ Checksums created!"

# ===== Run =====
run +args:
	@echo "▶️ Running (debug)…"
	swift run {{default_bin}} {{args}}

run-release +args:
	@echo "▶️ Running (release)…"
	{{release_bin}} {{args}}

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
