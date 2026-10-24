# Mana injects the parent sources; unflake evaluates the complete graph.
sources@{ nixpkgs, patchelf, flake-parts, git-hooks-nix, gitignore, upstream-flake-compat, upstream-nixpkgs }:
{ system ? builtins.currentSystem }:
let
  # The generated evaluator injects pinner-fetched sources into upstream flakes.
  upstream = (import ./unflake.nix).patchelf;
  # Our parent builds the wrapper; upstream uses its separate nixpkgs pin.
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
  upstreamPackage = upstream.packages.${system}.default;
in
{
  # Interpolation records the real upstream package as a runtime dependency.
  patchelf-demo = pkgs.writeShellScriptBin "patchelf-demo" ''
    exec ${upstreamPackage}/bin/patchelf "$@"
  '';
}
