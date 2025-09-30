let inputs = import "./nickel.lock.ncl" in
let organist = inputs.organist in

# Normalizer: accepts list of pkgs (strings/enums) -> record of nix imports
let normalizePkgs = fun pkgs =>
  std.array.fold_left
    (fun acc pkg =>
      let pkgName =
        if std.is_string pkg then pkg
        else if std.is_enum pkg then std.enum.to_string pkg
        else std.abort "Unsupported package reference: %{pkg}"
      in
      acc & { "%{pkgName}" = organist.import_nix "nixpkgs#%{pkgName}" }
    )
    {}
    pkgs
in

# external files
let buildPkgs = import "./build.ncl" in
let commonPkgs = import "./common.ncl" in
let devPkgs   = import "./dev.ncl" in

organist.OrganistExpression
& organist.tools.editorconfig
& {
  Schema,
  config | Schema = {
    shells = organist.shells.Bash,

    shells.build = {
      packages = normalizePkgs buildPkgs & normalizePkgs commonPkgs,
    },

    shells.dev = {
      packages = normalizePkgs devPkgs & normalizePkgs commonPkgs,
    },

    editorconfig.sections = {
      "*".indent_style = 'tab,
      "*".insert_final_newline = false,
    },
  },
}
| organist.modules.T
