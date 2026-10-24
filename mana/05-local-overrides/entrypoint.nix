# Request raw sources so importing the upstream list stays visible.
{ nixpkgs, systems }:
{ system ? builtins.currentSystem, systemsPath ? null }:
let
  pkgs = import nixpkgs { inherit system; config = {}; overlays = []; };
  # Selecting the local source leaves the lazy, locked systems argument unused.
  systemsSource = if systemsPath == null then systems else /. + systemsPath;
  supportedSystems = import systemsSource;
in
{
  systems = pkgs.writeText "systems.txt"
    (builtins.concatStringsSep "\n" supportedSystems + "\n");
}
