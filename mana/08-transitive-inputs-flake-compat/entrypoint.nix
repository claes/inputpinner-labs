# Raw dependencies keep fetching separate from upstream flake evaluation.
sources@{ nixpkgs, patchelf, flake-compat }:
{ system ? builtins.currentSystem }:
let
  pkgs = import nixpkgs { inherit system; config = {}; overlays = []; };
  sharedSource = import ./share-nixpkgs.nix {
    inherit pkgs;
    parentRevision = (builtins.fromJSON (builtins.readFile ./lock.json)).sources."/nixpkgs".locked.rev;
    nixpkgsSource = nixpkgs;
    patchelfSource = patchelf;
  };
  # Evaluate upstream's package output using the derived shared lock.
  upstream = (import flake-compat { src = sharedSource; inherit system; }).outputs;
in
{
  hello = pkgs.hello;
  # Consume the upstream package output after sharing the parent nixpkgs pin.
  patchelf = upstream.packages.${system}.default;
}
