{ system ? builtins.currentSystem, systemsPath ? null }:
let
  sources = import ./nix/tamal { inherit system; };
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
  # The argument changes only this evaluation; the saved remote pin stays intact.
  systemsSource = if systemsPath == null then sources.systems else /. + systemsPath;
  supportedSystems = import systemsSource;
in
pkgs.writeText "systems.txt"
  (builtins.concatStringsSep "\n" supportedSystems + "\n")
