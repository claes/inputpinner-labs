# Expose the system explicitly so the same pins can be used on another platform.
{ system ? builtins.currentSystem }:
let
  sources = import ./nix/tamal { inherit system; };
  # The parent package set creates our wrapper; upstream keeps its own nixpkgs.
  # Empty config and overlays exclude personal Nixpkgs settings from this example.
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
  # The pinner fetches sources; this separately pinned adapter evaluates outputs.
  # import-flake keeps upstream's locked inputs; no sharing override is applied.
  upstreamFlake = (import sources.flake-inputs).import-flake { src = sources.patchelf; };
  upstreamPackage = upstreamFlake.packages.${system}.default;
in
# Interpolation records the upstream package as a runtime dependency.
pkgs.writeShellScriptBin "patchelf-demo" ''
  exec ${upstreamPackage}/bin/patchelf "$@"
''
