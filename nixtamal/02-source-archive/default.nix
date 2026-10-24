{ system ? builtins.currentSystem }:
let
  # Resolve the two locked inputs before importing the package set.
  sources = import ./nix/tamal { inherit system; };
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
in
# Keep nixpkgs's build steps and checks; use our separately pinned source.
pkgs.hello.overrideAttrs (_: { src = sources.hello; })
