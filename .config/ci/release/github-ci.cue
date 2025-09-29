@extern(embed)
package release

#InstallNix: {
	name: "Install Nix"
	uses: "cachix/install-nix-action@v31"
	with: {
		extra_nix_config: "access-tokens = github.com=${{ secrets.GITHUB_TOKEN }}"
	}
}

workflows: release: {
	name: "Release"
	on: {
		push: tags: ["*"]
		workflow_dispatch: {}
	}
	defaults: run: shell: "bash"
	env: {
		RUSTFLAGS:   "--deny warnings"
		BINARY_NAME: "infat"
	}
	jobs: {
		prerelease: {
			"runs-on": "ubuntu-latest"
			outputs: value: "${{ steps.prerelease.outputs.value }}"
			steps: [{
				name: "Prerelease Check"
				id:   "prerelease"
				run:  string @embed(file=release.sh, type=text)
			}]
		}

		package: {
			strategy: {
				"fail-fast": false
				matrix: {
					target: [
						"aarch64-apple-darwin",
						"x86_64-apple-darwin",
					]
					include: [{
						target: "aarch64-apple-darwin"
						os:     "macos-latest"
					}, {
						target: "x86_64-apple-darwin"
						os:     "macos-latest"
					}]
				}
			}
			"runs-on": "${{ matrix.os }}"
			needs: ["prerelease"]
			environment: name: "main"
			steps: [{
				name: "Checkout code"
				uses: "actions/checkout@v4"
			},
				#InstallNix, {
					name: "Cache Cargo registry and git"
					uses: "actions/cache@v4"
					with: {
						path: """
						~/.cargo/registry/index
						~/.cargo/registry/cache
						~/.cargo/git/db
						"""
						key:            "${{ runner.os }}-cargo-registry-${{ hashFiles('Cargo.lock') }}"
						"restore-keys": "${{ runner.os }}-cargo-registry-"
					}
				}, {
					name: "Build and Package"
					run:  "nix develop --command just package ${{ matrix.target }}"
				}, {
					name: "Extract changelog for the tag"
					run:  "nix develop --command just create-notes ${{ github.ref_name }} release_notes.md CHANGELOG.md"
				}, {
					name: "Publish Release"
					uses: "softprops/action-gh-release@v2"
					if:   "startsWith(github.ref, 'refs/tags/')"
					with: {
						files:       "dist/${{ env.BINARY_NAME }}-${{ matrix.target }}.tar.gz"
						body_path:   "release_notes.md"
						draft:       false
						make_latest: true
						prerelease:  "${{ needs.prerelease.outputs.value }}"
						token:       "${{ secrets.PAT }}"
					}
				}]
		}

		checksum: {
			"runs-on": "ubuntu-latest"
			needs: ["package", "prerelease"]
			if: "startsWith(github.ref, 'refs/tags/')"
			environment: name: "main"
			steps: [#InstallNix, {
				name: "Download Release Archives"
				env: {
					GH_TOKEN: "${{ secrets.PAT }}"
					TAG_NAME: "${{ github.ref_name }}"
				}
				// The installation script for getting the release archive
				run: string @embed(file=repo-install.sh, type=text)
			}, {
				name: "Generate Checksums"
				run:  "nix develop --command just checksum dist"
			}, {
				name: "Publish Checksums"
				uses: "softprops/action-gh-release@v2"
				with: {
					files:      "dist/*.sum"
					draft:      false
					prerelease: "${{ needs.prerelease.outputs.value }}"
					token:      "${{ secrets.PAT }}"
				}
			}]
		}
	}
}
