# Mana injects the parent sources; unflake evaluates the complete graph.
sources@{ nixpkgs, patchelf, flake-parts, git-hooks-nix, gitignore, upstream-flake-compat }:
{ system ? builtins.currentSystem }:
let
  # The generated evaluator injects pinner-fetched sources into upstream flakes.
  upstream = (import ./unflake.nix).patchelf;
  # Unflake's deduplication rules route upstream nixpkgs edges to this source.
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
in
{
  hello = pkgs.hello;
  patchelf = upstream.packages.${system}.default;
}
