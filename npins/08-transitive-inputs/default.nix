{ system ? builtins.currentSystem }:
let
  sources = import ./npins;
  # This pinned package set supplies both the wrapper and upstream build tools.
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
  sharedSource = import ./share-nixpkgs.nix {
    inherit pkgs;
    parentRevision = (builtins.fromJSON (builtins.readFile ./npins/sources.json)).pins.nixpkgs.revision;
    nixpkgsSource = sources.nixpkgs;
    patchelfSource = sources.patchelf;
  };
  # The adapter follows upstream's existing edges through the replaced node.
  upstreamFlake = (import sources.flake-compat { src = sharedSource; inherit system; }).outputs;
  upstreamPackage = upstreamFlake.packages.${system}.default;
in
# Interpolation records the upstream package as a runtime dependency.
pkgs.writeShellScriptBin "patchelf-demo" ''
  exec ${upstreamPackage}/bin/patchelf "$@"
''
