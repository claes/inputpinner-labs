{ system ? builtins.currentSystem }:
let
  sources = import ./sources.nix;
  # The generated evaluator injects pinner-fetched sources into upstream flakes.
  upstream = (import ./unflake.nix).patchelf;
  # Apply the upstream recipe to our parent package set.
  pkgs = import sources.nixpkgs {
    inherit system;
    config = {};
    overlays = [ upstream.overlays.default ];
  };
in
pkgs.patchelf-new
