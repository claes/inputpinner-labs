{ system ? builtins.currentSystem, inputsOverrides ? {} }:
let
  # Read the sources already fetched by the native pinner.
  sources = import ./nix/sources.nix;

  # The library loader binds sources and project self; follows and outputs come below.
  with-inputs = (import sources.with-inputs).from.niv ./.;

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
