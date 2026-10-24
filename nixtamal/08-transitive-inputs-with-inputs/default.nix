{ system ? builtins.currentSystem, inputsOverrides ? {} }:
let
  # The native loader reads Nixtamal's pins and supplies project self.
  with-inputs =
    (import (import ./nix/tamal {}).with-inputs).from.nixtamal ./.;

  # Input relationships are separate from the package definitions.
  follows = {
    # Make upstream patchelf use the same nixpkgs as our own hello package.
    patchelf.inputs.nixpkgs.follows = "nixpkgs";
    # Other inputs named nixpkgs follow it automatically.
    nixpkgs-lib.follows = "nixpkgs";
    nixpkgs-stable.follows = "nixpkgs";
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
    in
    {
      hello = pkgs.hello;
      # Upstream's output now uses the same nixpkgs as hello.
      patchelf = upstream.packages.${system}.default;
    };
in
# Caller overrides are applied after this example's follows declarations.
with-inputs [ follows inputsOverrides ] outputs
