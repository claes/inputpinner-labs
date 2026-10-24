# Mana supplies the native source records by argument name.
sources@{ nixpkgs, patchelf, with-inputs, flake-parts, git-hooks-nix, upstream-nixpkgs }:
{ system ? builtins.currentSystem, inputsOverrides ? {} }:
let
  # Bind sources and project self; the remaining arguments are follows and outputs.
  with-inputs = (import sources.with-inputs) (sources // {
    self.outPath = ./.;
  });

  # Input relationships are separate from the package definitions.
  follows = {
    # Keep upstream's graph separate from the parent's nixpkgs.
    patchelf.inputs.nixpkgs.follows = "upstream-nixpkgs";
    git-hooks-nix.inputs.nixpkgs.follows = "upstream-nixpkgs";
    nixpkgs-lib.follows = "upstream-nixpkgs";
    nixpkgs-stable.follows = "upstream-nixpkgs";
    # Upstream disconnects these optional development inputs too.
    flake-compat.follows = "";
    gitignore.follows = "";
  };

  # Define our outputs using resolved flake inputs, like a flake outputs function.
  outputs = inputs:
    let
      upstream = inputs.patchelf;
      pkgs = import inputs.nixpkgs {
        inherit system;
        config = {};
        overlays = [];
      };
      upstreamPackage = upstream.packages.${system}.default;
    in
    {
      # Our parent-built wrapper forwards arguments to upstream's package output.
      patchelf-demo = pkgs.writeShellScriptBin "patchelf-demo" ''
        exec ${upstreamPackage}/bin/patchelf "$@"
      '';
    };
in
# Caller overrides are applied after this example's follows declarations.
with-inputs [ follows inputsOverrides ] outputs
