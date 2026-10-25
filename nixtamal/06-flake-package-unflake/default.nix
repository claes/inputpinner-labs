# Expose the system explicitly so the same pins can be used on another platform.
{ system ? builtins.currentSystem }:
let
  sources = import ./sources.nix;
  # The generated evaluator injects pinner-fetched sources into upstream flakes.
  upstream = (import ./unflake.nix).patchelf;
  # Our parent builds the wrapper; upstream uses its separate nixpkgs pin.
  # Empty config and overlays exclude personal Nixpkgs settings from this example.
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
  upstreamPackage = upstream.packages.${system}.default;
in
# Forward arguments and retain the upstream executable as a runtime dependency.
pkgs.writeShellScriptBin "patchelf-demo" ''
    exec ${upstreamPackage}/bin/patchelf "$@"
  ''
