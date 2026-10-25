# Expose the system explicitly so the same pins can be used on another platform.
{ system ? builtins.currentSystem }:
let
  # Resolve the two locked inputs before importing the package set.
  sources = import ./nix/tamal { inherit system; };
  # Empty config and overlays exclude personal Nixpkgs settings from this example.
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
in
# Override only the source to illustrate an independent pin while retaining
# Nixpkgs' build steps and checks for the same Hello release.
pkgs.hello.overrideAttrs (_: { src = sources.hello; })
