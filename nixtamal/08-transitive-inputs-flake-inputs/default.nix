# Expose the system explicitly so the same pins can be used on another platform.
{ system ? builtins.currentSystem }:
let
  sources = import ./nix/tamal { inherit system; };
  # Our own package and upstream patchelf receive this same nixpkgs source.
  # Empty config and overlays exclude personal Nixpkgs settings from this example.
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
