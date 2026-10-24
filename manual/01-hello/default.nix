{ system ? builtins.currentSystem }:
let
  # This small, locally maintained record replaces a pinner's lockfile.
  pin = builtins.fromJSON (builtins.readFile ./pin.json);

  # The hash describes the unpacked tree, not the compressed archive bytes.
  source = builtins.fetchTarball { inherit (pin) url sha256; };

  # No channels or ambient nixpkgs are needed to consume the pin.
  pkgs = import source { inherit system; config = {}; overlays = []; };
in
pkgs.hello
