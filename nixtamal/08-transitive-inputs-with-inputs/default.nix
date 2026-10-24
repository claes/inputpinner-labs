{ system ? builtins.currentSystem }:
let
  sources = import ./nix/tamal {};
  # Preserve native metadata; wrap bare source paths with outPath.
  asSource = source:
    if builtins.isAttrs source then source else { outPath = source; };
  # Use the parent nixpkgs throughout the flake input graph.
  fetched = builtins.mapAttrs (_: asSource) {
    nixpkgs = sources.nixpkgs;
    inherit (sources) patchelf flake-parts git-hooks-nix;
  };
  # Evaluate flake outputs from sources fetched by the native resolver.
  inputs = (import sources.with-inputs) fetched {
    nixpkgs-lib.follows = "nixpkgs";
    nixpkgs-stable.follows = "nixpkgs";
    # Upstream disconnects these optional development inputs too.
    flake-compat.follows = "";
    gitignore.follows = "";
    # Explicit equivalent of a flake input follows declaration.
    patchelf.inputs.nixpkgs.follows = "nixpkgs";
  };
  upstream = inputs.patchelf;
  # The parent package set builds our own outputs.
  pkgs = import sources.nixpkgs {
    inherit system;
    config = {};
    overlays = [];
  };
in
{
  hello = pkgs.hello;
  # Consume the upstream package output with the same nixpkgs as hello.
  patchelf = upstream.packages.${system}.default;
}
