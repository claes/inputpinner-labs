# Expose the system explicitly so the same pins can be used on another platform.
{ system ? builtins.currentSystem }:
let
  # Bootstrap the evaluator from our own pin; its native loader keeps Nixtamal
  # responsible for fetching and supplies project self from this directory.
  # Reading their fetched Nix files requires Import From Derivation (IFD).
  with-inputs =
    (import (import ./nix/tamal {}).with-inputs).from.nixtamal ./.;

  # Input relationships are separate from the package definitions.
  follows = {
    # Share the parent pin so updating it changes both Hello and upstream patchelf.
    patchelf.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Define our outputs using resolved flake inputs, like a flake outputs function.
  outputs = inputs:
    let
      upstream = inputs.patchelf;
      # Hello uses the same source that the follows declaration gives to patchelf.
      pkgs = import inputs.nixpkgs {
        inherit system;
        # Ignore personal Nixpkgs settings so the example is reproducible.
        config = {};
        # Use the parent package set without personal overlays.
        overlays = [];
      };
    in
    {
      hello = pkgs.hello;
      # Upstream's output now uses the same nixpkgs as hello.
      patchelf = upstream.packages.${system}.default;
    };
in
with-inputs follows outputs
