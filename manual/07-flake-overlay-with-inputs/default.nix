{ system ? builtins.currentSystem, inputsOverrides ? {} }:
let
  # Fetch the recorded archives and expose each unpacked tree as a source.
  sources = builtins.mapAttrs (_: pin: {
    outPath = builtins.fetchTarball { inherit (pin) url sha256; };
  }) (builtins.fromJSON (builtins.readFile ./pins.json));

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
        overlays = [ upstream.overlays.default ];
      };
    in
    {
      # The overlay adds this attribute and preserves the original pkgs.patchelf.
      patchelf-new = pkgs.patchelf-new;
    };
in
# Caller overrides are applied after this example's follows declarations.
with-inputs [ follows inputsOverrides ] outputs
