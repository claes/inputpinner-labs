{ system ? builtins.currentSystem }:
let
  sources = import ./nix/sources.nix { inherit system; };
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
  # The resolver supplies the remote pin or this invocation's local replacement.
  supportedSystems = import sources.systems;
in
pkgs.writeText "systems.txt"
  (builtins.concatStringsSep "\n" supportedSystems + "\n")
