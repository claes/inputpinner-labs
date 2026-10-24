# Mana injects the parent sources; unflake evaluates the complete graph.
sources@{ nixpkgs, patchelf, flake-parts, git-hooks-nix, gitignore, upstream-flake-compat, upstream-nixpkgs }:
{ system ? builtins.currentSystem }:
let
  # The generated evaluator injects pinner-fetched sources into upstream flakes.
  upstream = (import ./unflake.nix).patchelf;
  # Apply the upstream recipe to our parent package set.
  pkgs = import sources.nixpkgs {
    inherit system;
    config = {};
    overlays = [ upstream.overlays.default ];
  };
in
{ patchelf-new = pkgs.patchelf-new; }
