{ system ? builtins.currentSystem }:
let
  sources = import ./.tack;
  # The native resolver shares this flake with upstream through all_follow.
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
  # Select the upstream package output after its inputs have been shared.
  upstreamPackage = sources.patchelf.packages.${system}.default;
in
# Interpolation records the upstream package as a runtime dependency.
pkgs.writeShellScriptBin "patchelf-demo" ''
  exec ${upstreamPackage}/bin/patchelf "$@"
''
