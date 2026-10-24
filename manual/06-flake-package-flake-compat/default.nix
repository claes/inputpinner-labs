{ system ? builtins.currentSystem }:
let
  sources = builtins.mapAttrs (_: pin: builtins.fetchTarball {
    inherit (pin) url sha256;
  }) (builtins.fromJSON (builtins.readFile ./pins.json));
  # The parent package set creates our wrapper; upstream keeps its own nixpkgs.
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
  # The pinner fetches sources; this separately pinned adapter evaluates outputs.
  # It reads patchelf's own flake.lock, retaining the upstream dependency graph.
  upstreamFlake = (import sources.flake-compat { src = sources.patchelf; inherit system; }).outputs;
  upstreamPackage = upstreamFlake.packages.${system}.default;
in
# Interpolation records the upstream package as a runtime dependency.
pkgs.writeShellScriptBin "patchelf-demo" ''
  exec ${upstreamPackage}/bin/patchelf "$@"
''
