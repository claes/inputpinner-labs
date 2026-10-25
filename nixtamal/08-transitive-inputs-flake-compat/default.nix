# Expose the system explicitly so the same pins can be used on another platform.
{ system ? builtins.currentSystem }:
let
  sources = import ./nix/tamal { inherit system; };
  # This pinned package set supplies both Hello and upstream build tools.
  # Empty config and overlays exclude personal Nixpkgs settings from this example.
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
  # This adapter has no input override API, so stage an upstream lock replacement.
  # Read the active lock revision so parent updates work without changing seed files.
  sharedSource = import ./share-nixpkgs.nix {
    inherit pkgs;
    parentRevision = (builtins.fromJSON (builtins.readFile ./nix/tamal/lock.json)).i.nixpkgs.fv;
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
