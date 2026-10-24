# Mana injects these three raw, locked sources into the consumer.
sources@{ nixpkgs, patchelf, flake-inputs }:
{ system ? builtins.currentSystem }:
let
  # Our own package and upstream patchelf receive this same nixpkgs source.
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
  # The adapter evaluates flake outputs with our source replacing upstream's pin.
  upstream = (import sources.flake-inputs).import-flake {
    src = sources.patchelf;
    overrides.nixpkgs = sources.nixpkgs;
  };
in
{
  hello = pkgs.hello;
  # This is still upstream's package output, now built with our nixpkgs.
  patchelf = upstream.packages.${system}.default;
}
