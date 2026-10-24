{ system ? builtins.currentSystem }:
let
  pins = builtins.fromJSON (builtins.readFile ./pins.json);
  # Each input has its own URL and unpacked-tree hash.
  sources = {
    nixpkgs = builtins.fetchTarball { inherit (pins.nixpkgs) url sha256; };
    hello = builtins.fetchTarball { inherit (pins.hello) url sha256; };
  };
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
in
# Source management is separate from the package recipe maintained in nixpkgs.
pkgs.hello.overrideAttrs (_: { src = sources.hello; })
