{ system ? builtins.currentSystem }:
let
  sources = import ./npins;
  # This pinned package set supplies both Hello and upstream build tools.
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
  sharedSource = import ./share-nixpkgs.nix {
    inherit pkgs;
    parentRevision = (builtins.fromJSON (builtins.readFile ./npins/sources.json)).pins.nixpkgs.revision;
    nixpkgsSource = sources.nixpkgs;
    patchelfSource = sources.patchelf;
  };
  # The adapter follows upstream's existing edges through the replaced node.
  upstream = (import sources.flake-compat { src = sharedSource; inherit system; }).outputs;
in
{
  hello = pkgs.hello;
  # Consume the upstream package output after sharing the parent nixpkgs pin.
  patchelf = upstream.packages.${system}.default;
}
