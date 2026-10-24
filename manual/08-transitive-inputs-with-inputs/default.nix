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
