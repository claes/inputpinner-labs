# Raw dependencies keep fetching separate from upstream flake evaluation.
{ nixpkgs, patchelf, flake-inputs }:
{ system ? builtins.currentSystem }:
let
  pkgs = import nixpkgs { inherit system; config = {}; overlays = []; };
  # Read upstream's own lock through the separately pinned compatibility adapter.
  upstreamFlake = (import flake-inputs).import-flake { src = patchelf; };
  upstreamPackage = upstreamFlake.packages.${system}.default;
in
{
  # The upstream package becomes a runtime dependency of our own program.
  patchelf-demo = pkgs.writeShellScriptBin "patchelf-demo" ''
    exec ${upstreamPackage}/bin/patchelf "$@"
  '';
}
