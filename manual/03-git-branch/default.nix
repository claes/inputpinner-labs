{ system ? builtins.currentSystem }:
let
  pins = builtins.fromJSON (builtins.readFile ./pins.json);
  sources = {
    nixpkgs = builtins.fetchTarball { inherit (pins.nixpkgs) url sha256; };
    # The stored URL contains a commit, not main; builds cannot follow the branch.
    systems = builtins.fetchTarball { inherit (pins.systems) url sha256; };
  };
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
  supportedSystems = import sources.systems;
in
pkgs.writeText "systems.txt"
  (builtins.concatStringsSep "\n" supportedSystems + "\n")
