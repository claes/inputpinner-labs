# Mana injects the locked raw source records by argument name.
sources@{ nixpkgs, patchelf, with-inputs, flake-parts, git-hooks-nix, upstream-nixpkgs }:
{ system ? builtins.currentSystem }:
let
  # Preserve native metadata; wrap bare source paths with outPath.
  asSource = source:
    if builtins.isAttrs source then source else { outPath = source; };
  # Scope name matching to upstream's separately pinned nixpkgs.
  fetched = builtins.mapAttrs (_: asSource) {
    nixpkgs = sources.upstream-nixpkgs;
    inherit (sources) patchelf flake-parts git-hooks-nix;
  };
  # Evaluate flake outputs from sources fetched by the native resolver.
  inputs = (import sources.with-inputs) fetched {
    nixpkgs-lib.follows = "nixpkgs";
    nixpkgs-stable.follows = "nixpkgs";
    # Upstream disconnects these optional development inputs too.
    flake-compat.follows = "";
    gitignore.follows = "";
  };
  upstream = inputs.patchelf;
  # The parent package set builds our own outputs.
  pkgs = import sources.nixpkgs {
    inherit system;
    config = {};
    overlays = [];
  };
  upstreamPackage = upstream.packages.${system}.default;
in
{
  patchelf-demo = pkgs.writeShellScriptBin "patchelf-demo" ''
  exec ${upstreamPackage}/bin/patchelf "$@"
'';
}
