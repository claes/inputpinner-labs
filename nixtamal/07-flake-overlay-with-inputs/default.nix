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
    # Override automatic name matching so upstream keeps its own nixpkgs pin.
    patchelf.inputs.nixpkgs.follows = "upstream-nixpkgs";
  };

  # Define our outputs using resolved flake inputs, like a flake outputs function.
  outputs = inputs:
    let
      upstream = inputs.patchelf;
      # Apply the overlay to our parent so its recipe uses our compiler and helpers.
      pkgs = import inputs.nixpkgs {
        inherit system;
        # Ignore personal Nixpkgs settings so the example is reproducible.
        config = {};
        overlays = [ upstream.overlays.default ];
      };
    in
    {
      # The overlay adds this attribute and preserves the original pkgs.patchelf.
      patchelf-new = pkgs.patchelf-new;
    };
in
with-inputs follows outputs
