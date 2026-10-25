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
      # The parent supplies the wrapper builder; patchelf uses upstream's package set.
      pkgs = import inputs.nixpkgs {
        inherit system;
        # Ignore personal Nixpkgs settings so the example is reproducible.
        config = {};
        # Use the parent package set without personal overlays.
        overlays = [];
      };
      upstreamPackage = upstream.packages.${system}.default;
    in
    {
      # The store-path reference retains upstream patchelf as a runtime dependency;
      # forwarding arguments lets us use its executable through our own package.
      patchelf-demo = pkgs.writeShellScriptBin "patchelf-demo" ''
        exec ${upstreamPackage}/bin/patchelf "$@"
      '';
    };
in
with-inputs follows outputs
