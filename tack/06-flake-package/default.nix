{ system ? builtins.currentSystem }:
let
  sources = import ./.tack;
  # The parent package set creates our wrapper; upstream keeps its own nixpkgs.
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
  # The native resolver evaluates patchelf's flake with its upstream lock.
  upstreamPackage = sources.patchelf.packages.${system}.default;
in
# Interpolation records the upstream package as a runtime dependency.
pkgs.writeShellScriptBin "patchelf-demo" ''
  exec ${upstreamPackage}/bin/patchelf "$@"
''
