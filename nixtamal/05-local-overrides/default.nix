# Expose the system explicitly so the same pins can be used on another platform.
{ system ? builtins.currentSystem, systemsPath ? null }:
let
  sources = import ./nix/tamal { inherit system; };
  # Empty config and overlays exclude personal Nixpkgs settings from this example.
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
  # Keep local edits outside the saved remote pin; removing the argument restores it.
  # Convert the absolute string supplied by --argstr into a Nix path before import.
  systemsSource = if systemsPath == null then sources.systems else /. + systemsPath;
  supportedSystems = import systemsSource;
in
# Write the list as data so observing the input needs no compiler or cross build.
pkgs.writeText "systems.txt"
  (builtins.concatStringsSep "\n" supportedSystems + "\n")
