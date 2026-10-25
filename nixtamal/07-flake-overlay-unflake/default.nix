# Expose the system explicitly so the same pins can be used on another platform.
{ system ? builtins.currentSystem }:
let
  sources = import ./sources.nix;
  # The generated evaluator injects pinner-fetched sources into upstream flakes.
  upstream = (import ./unflake.nix).patchelf;
  # Apply the upstream recipe to our parent so it uses our compiler and helpers.
  pkgs = import sources.nixpkgs {
    inherit system;
    # Ignore personal Nixpkgs settings so the example is reproducible.
    config = {};
    # Apply the recipe to our parent rather than using upstream's package output.
    overlays = [ upstream.overlays.default ];
  };
in
pkgs.patchelf-new
