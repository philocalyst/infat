#!/usr/bin/env just
 
# --- Settings --- #
set shell := ["nu", "-c"]
set positional-arguments := true
set allow-duplicate-variables := true
set windows-shell := ["nu", "-c"]
set dotenv-load := true

# --- Variables --- #
project_root := justfile_directory()
output_directory := project_root + "/dist"
build_directory := `cargo metadata --format-version 1 | jq -r .target_directory`
system := `rustc --version --verbose |  grep '^host:' | awk '{print $2}'`
main_package := "infat"

# ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰ #
#      Recipes      #
# ▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰▰ #

[doc('List all available recipes')]
default:
    @just --list

# --- Build & Check --- #
[doc('Check workspace for compilation errors')]
[group('build')]
check:
    @echo "🔎 Checking workspace..."
    cargo check --workspace
    cargo clippy
    typos --sort

[doc('Build workspace in debug mode')]
[group('build')]
build target="aarch64-apple-darwin" package=(main_package):
    @echo "🔨 Building workspace (debug)..."
    cargo build --workspace --bin '{{ main_package }}' --target '{{ target }}'

[doc('Build workspace in release mode')]
[group('build')]
build-release target=(system) package=(main_package):
    @echo "🚀 Building workspace (release) for {{ target }}…"
    cargo build --workspace --release --bin '{{ main_package }}' --target '{{ target }}'

# --- Packaging --- #
[doc('Package release binary with completions for distribution')]
[group('packaging')]
package target=(system):
    #!/usr/bin/env nu
    def build_error [msg: string, error?: record] {
        if ($error != null) {
            let annotated_error = ($error | upsert msg $'($msg): ($error.msg)')
            $annotated_error.rendered | print --stderr
        } else {
            (error make --unspanned { msg: $msg }) | print --stderr
        }
        exit 1
    }

    print "📦 Packaging release binary…"


    let target = '{{ target }}'
    let prime = '{{ main_package }}'
    let out = "{{ output_directory }}"
    let artifact_dir = $'{{ build_directory }}/($target)/release'

    try {
        just build-release $target

        print $'🛬 Destination is ($out)'

        # Windows the only one that has an executable extension
        let ext = if ($target | str contains 'windows-msvc') { '.exe' } else { '' }

        let bin_path = $'($artifact_dir)/($prime)($ext)' # Where rust puts the binary artifact
        let out_path = $'($out)/($prime)($ext)'

        # Create output directory structure
        try {
            mkdir $out
        } catch {|e| 
            build_error $"Failed to create directory: ($out)" $e
        }

        # Copy completion scripts
        let completions = [$'($prime).bash', $'($prime).elv', $'($prime).fish', $'_($prime).ps1', $'_($prime)']

        for completion in $completions {
            let src = $'($artifact_dir)/($completion)'
            let dst = $'($out)/($completion)'

            if ($src | path exists) {
                try {
                    cp --force $src $dst # Using force here because default nu copy only works with existing files otherwise
                    print $"('Successfully copied completion to destination:' | ansi gradient --fgstart '0x00ff00' --fgend '0xff0080' --bgstart '0x1a1a1a' --bgend '0x0d0d0d') (basename $src)"
                } catch {|e| 
                    build_error $"Failed to copy completion script ($src)" $e
                }
            } else {
                print --stderr $"Warning: completion script missing: ($src)"
            }
        }

        # Copy main binary
        try {
            cp --force $bin_path $out_path
            print $"('Successfully copied binary to destination:' | ansi gradient --fgstart '0x00ff00' --fgend '0xff0080' --bgstart '0x1a1a1a' --bgend '0x0d0d0d') (basename $bin_path)"
        } catch {  |e| 
            build_error $"Failed to copy binary ($bin_path)" $e
        }

    } catch {  |e| 
        build_error "Packaging failed" $e
    }

[doc('Generate checksums for distribution files')]
[group('packaging')]
checksum directory=(output_directory):
    #!/usr/bin/env nu
    def build_error [msg: string, error?: record] {
        if ($error != null) {
            let annotated_error = ($error | upsert msg $'($msg): ($error.msg)')
            $annotated_error.rendered | print --stderr
            exit 1
        } else {
            (error make --unspanned { msg: $msg }) | print --stderr
            exit 1
        }
    }

    let dir = '{{ directory }}'
    print $"🔒 Generating checksums in '($dir)'…"

    # Validate directory exists
    if not ($dir | path exists) {
        build_error $"'($dir)' is not a directory."
    }

    try {
        cd $dir

        # Remove existing checksum files
        try {
            glob '*.sum' | each { |file| rm $file }
        } catch {
            # Ignore errors if no .sum files exist
        }

        # Get all files except checksum files
        let files = ls | where type == file | where name !~ '\.sum$' | get name

        if (($files | length) == 0) {
            print --stderr "Warning: No files found to checksum"
            return
        }

        # Generate SHA256 checksums
        try {
            let sha256_results = $files | each { |file| 
                let hash = (open --raw $file | hash sha256)
                $"($hash)  ./($file | path basename)"
            }
            $sha256_results | str join (char newline) | save SHA256.sum
        } catch {|e| 
            build_error $"Failed to generate SHA256 checksums" $e
        }

        # Generate MD5 checksums
        try {
            let md5_results = $files | each { |file| 
                let hash = (open --raw $file | hash md5)
                $"($hash)  ./($file | path basename)"
            }
            $md5_results | str join (char newline) | save MD5.sum
        } catch {|e| 
            build_error $"Failed to generate MD5 checksums" $e
        }

        # Generate BLAKE3 checksums (using b3sum command)
        try {
            let b3_results = $files | each { |file| 
                let result = (run-external 'b3sum' $file | complete)
                if $result.exit_code != 0 {
                    build_error $"b3sum failed for ($file): ($result.stderr)"
                }
                let hash = ($result.stdout | str trim | split row ' ' | get 0)
                $"($hash)  ./($file | path basename)"
            }
            $b3_results | str join (char newline) | save BLAKE3.sum
        } catch {|e| 
            build_error $"Failed to generate BLAKE3 checksums" $e
        }

        print $"✅ Checksums created in '($dir)'"

    } catch {|e| 
        build_error $"Checksum generation failed" $e
    }

[doc('Compress all release packages into tar.gz archives')]
[group('packaging')]
compress directory=(output_directory):
    #!/usr/bin/env nu
    def build_error [msg: string, error?: record] {
        if ($error != null) {
            let annotated_error = ($error | upsert msg $'($msg): ($error.msg)')
            $annotated_error.rendered | print --stderr
            exit 1
        } else {
            (error make --unspanned { msg: $msg }) | print --stderr
            exit 1
        }
    }

    let prime = '{{ main_package }}'
    let sys = '{{ system }}'

    print "🗜️ Compressing release packages..."

    let dir = '{{ directory }}'
    if not ($dir | path exists) {
        build_error $"Directory '($dir)' does not exist"
    }

    try {
        # Find all package directories
        mut package_dirs = ls $dir | where type == dir | get name

        if (($package_dirs | length) == 0) {
            # Just one package found to compress
            $package_dirs = ($package_dirs | append $dir)
        }

        for pkg_dir in $package_dirs {
            let pkg_name = ($pkg_dir | path basename)
            print $"🎁 Compressing package: ($pkg_name)"

            try {
                let parent_dir = ($pkg_dir | path dirname)
                let archive_name = $'($prime)-($sys).tar.gz'

                # Use tar command to create compressed archive
                let result = (run-external 'tar' '-czf' $archive_name '-C' $parent_dir $pkg_name | complete)

                if $result.exit_code != 0 {
                    build_error $"Failed to create archive for ($pkg_name): ($result.stderr)"
                }

                print $"✅ Successfully compressed ($pkg_name)"

            } catch { |e| 
                build_error $"Compression failed for ($pkg_name)" $e
            }
        }

        print "🎉 All packages compressed successfully!"

    } catch { |e| 
        build_error $"Compression process failed" $e
    }

[doc('Complete release pipeline: build, checksum, and compress')]
[group('packaging')]
release: build-release
    just checksum

# --- Execution --- #
[doc('Run application in debug mode')]
[group('execution')]
run package=(main_package) +args="":
    @echo "▶️ Running {{ package }} (debug)..."
    cargo run --bin '{{ package }}' -- '$@'

[doc('Run application in release mode')]
[group('execution')]
run-release package=(main_package) +args="":
    @echo "▶️ Running '{{ package }}' (release)..."
    cargo run --bin '{{ package }}' --release -- '$@'

# --- Testing --- #
[doc('Run all workspace tests')]
[group('testing')]
test:
    @echo "🧪 Running workspace tests..."
    cargo test --workspace

[doc('Run workspace tests with additional arguments')]
[group('testing')]
test-with +args:
    @echo "🧪 Running workspace tests with args: '$@'"
    cargo test --workspace -- '$@'

# --- Code Quality --- #
[doc('Format all Rust code in the workspace')]
[group('quality')]
fmt:
    @echo "💅 Formatting Rust code..."
    cargo fmt 

[doc('Check if Rust code is properly formatted')]
[group('quality')]
fmt-check:
    @echo "💅 Checking Rust code formatting..."
    cargo fmt 

[doc('Lint code with Clippy in debug mode')]
[group('quality')]
lint:
    @echo "🧹 Linting with Clippy (debug)..."
    cargo clippy --workspace -- -D warnings

[doc('Automatically fix Clippy lints where possible')]
[group('quality')]
lint-fix:
    @echo "🩹 Fixing Clippy lints..."
    cargo clippy --workspace --fix --allow-dirty --allow-staged

# --- Documentation --- #
[doc('Generate project documentation')]
[group('common')]
doc:
    @echo "📚 Generating documentation..."
    cargo doc --workspace --no-deps

[doc('Generate and open project documentation in browser')]
[group('common')]
doc-open: doc
    @echo "📚 Opening documentation in browser..."
    cargo doc --workspace --no-deps --open

# --- Maintenance --- #
[doc('Extract release notes from changelog for specified tag')]
[group('common')]
create-notes raw_tag outfile changelog:
    #!/usr/bin/env nu
    def build_error [msg: string, error?: record] {
        if ($error != null) {
            let annotated_error = ($error | upsert msg $'($msg): ($error.msg)')
            $annotated_error.rendered | print --stderr
            exit 1
        } else {
            (error make --unspanned { msg: $msg }) | print --stderr
            exit 1
        }
    }

    let tag_v = '{{ raw_tag }}'
    let tag = ($tag_v | str replace --regex '^v' '')  # Remove prefix v
    let outfile = '{{ outfile }}'
    let changelog_file = '{{ changelog }}'

    try {
        # Verify changelog exists
        if not ($changelog_file | path exists) {
            build_error $"($changelog_file) not found."
        }

        print $"Extracting notes for tag: ($tag_v) \(searching for section [($tag)]\)"

        # Write header to output file
        "# What's new\n" | save --force $outfile

        # Read and process changelog
        let content = (open $changelog_file | lines)

        # Find the start of the target section
        let start_idx = ($content | enumerate | where ($it.item | str contains $tag) | get index | first)

        if ($start_idx | is-empty) {
            build_error $"Could not find tag ($tag) in ($changelog_file)"
        }

        # Find the end of the target section (next ## [ header)
        let remaining_lines = ($content | skip ($start_idx + 1))
        let next_section_idx = ($remaining_lines | enumerate | where item =~ '^## \[' | get index | first)

        let section_lines = if ($next_section_idx | is-empty) {
            $remaining_lines
        } else {
            $remaining_lines | take $next_section_idx
        }

        # Append section content to output file
        $section_lines | str join (char newline) | save --append $outfile

        # Check if output file has meaningful content
        let output_size = (open $outfile | str length)
        if $output_size > 20 {  # More than just the header
            print $"Successfully extracted release notes to '($outfile)'."
        } else {
            print --stderr $"Warning: '($outfile)' appears empty. Is '($tag)' present in '($changelog_file)'?"
        }

    } catch { |e| 
        build_error $"Failed to extract release notes:" $e
    }

[doc('Update Cargo dependencies')]
[group('maintenance')]
update:
    @echo "🔄 Updating dependencies..."
    cargo update

[doc('Clean build artifacts')]
[group('maintenance')]
clean:
    @echo "🧹 Cleaning build artifacts..."
    cargo clean

# --- Installation --- #
[doc('Build and install binary to system')]
[group('installation')]
install package=(main_package): build-release
    @echo "💾 Installing {{ main_package }} binary..."
    cargo install --bin '{{ package }}'

[doc('Force install binary')]
[group('installation')]
install-force package=(main_package): build-release
    @echo "💾 Force installing {{ main_package }} binary..."
    cargo install --bin '{{ package }}' --force

# --- Aliases --- #
alias b    := build
alias br   := build-release
alias c    := check
alias t    := test
alias f    := fmt
alias l    := lint
alias lf   := lint-fix
alias cl   := clean
alias up   := update
alias i    := install
alias ifo  := install-force
alias rr   := run-release
