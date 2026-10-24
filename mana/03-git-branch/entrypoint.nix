# Request raw sources so importing the upstream list stays visible.
{ nixpkgs, systems }:
{ system ? builtins.currentSystem }:
let
  pkgs = import nixpkgs { inherit system; config = {}; overlays = []; };
  supportedSystems = import systems;
in
{
  systems = pkgs.writeText "systems.txt"
    (builtins.concatStringsSep "\n" supportedSystems + "\n");
}
