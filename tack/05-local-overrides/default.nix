{ system ? builtins.currentSystem, systemsPath ? null }:
let
  # The resolver merges these replacements over its locked source attributes.
  sources = import ./.tack {
    overrides = if systemsPath == null then {} else { systems = /. + systemsPath; };
  };
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
  # The resolver supplies the remote pin or this invocation's local replacement.
  supportedSystems = import sources.systems;
in
pkgs.writeText "systems.txt"
  (builtins.concatStringsSep "\n" supportedSystems + "\n")
