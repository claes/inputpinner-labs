{ system ? builtins.currentSystem }:
let
  sources = import ./nix/sources.nix { inherit system; };
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
  # This import reads the locked commit even when the tracked branch has moved.
  supportedSystems = import sources.systems;
in
pkgs.writeText "systems.txt"
  (builtins.concatStringsSep "\n" supportedSystems + "\n")
