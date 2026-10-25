{ system ? builtins.currentSystem }:
let
  # The native loader reads Nixtamal's pins and supplies project self.
  with-inputs =
    (import (import ./nix/tamal {}).with-inputs).from.nixtamal ./.;

  # Input relationships are separate from the package definitions.
  follows = {
    # Preserve upstream's nixpkgs independently of our parent.
    patchelf.inputs.nixpkgs.follows = "upstream-nixpkgs";
  };

  # Define our outputs using resolved flake inputs, like a flake outputs function.
  outputs = inputs:
    let
      upstream = inputs.patchelf;
      pkgs = import inputs.nixpkgs {
        inherit system;
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
