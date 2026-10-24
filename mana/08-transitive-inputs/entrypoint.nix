# Raw dependencies keep fetching separate from upstream flake evaluation.
{ nixpkgs, patchelf, flake-compat }:
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
  upstreamFlake = (import flake-compat { src = sharedSource; inherit system; }).outputs;
  upstreamPackage = upstreamFlake.packages.${system}.default;
in
{
  # The upstream package becomes a runtime dependency of our own program.
  patchelf-demo = pkgs.writeShellScriptBin "patchelf-demo" ''
    exec ${upstreamPackage}/bin/patchelf "$@"
  '';
}
