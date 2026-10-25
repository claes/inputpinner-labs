# Allow explicit platform selection; nix-build defaults to the current host.
{ system ? builtins.currentSystem }:
let
  # The generated resolver exposes the locked input as a source path.
  sources = import ./nix/tamal { inherit system; };

  # Import the locked source instead of an ambient channel; empty config and
  # overlays also exclude personal Nixpkgs settings from this example.
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
in
# Reuse an existing package so pinning remains the only new concept.
pkgs.hello
