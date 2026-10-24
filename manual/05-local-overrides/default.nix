{ system ? builtins.currentSystem, systemsPath ? null }:
let
  pins = builtins.fromJSON (builtins.readFile ./pins.json);
  sources = {
    nixpkgs = builtins.fetchTarball { inherit (pins.nixpkgs) url sha256; };
    # The stored URL contains a commit, not main; builds cannot follow the branch.
    systems = builtins.fetchTarball { inherit (pins.systems) url sha256; };
  };
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
  # The argument changes only this evaluation; the saved remote pin stays intact.
  systemsSource = if systemsPath == null then sources.systems else /. + systemsPath;
  supportedSystems = import systemsSource;
in
pkgs.writeText "systems.txt"
  (builtins.concatStringsSep "\n" supportedSystems + "\n")
