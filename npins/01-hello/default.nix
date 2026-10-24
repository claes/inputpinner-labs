# Allow explicit platform selection; nix-build defaults to the current host.
{ system ? builtins.currentSystem }:
let
  # The generated resolver exposes the locked input as a source path.
  sources = import ./npins;

  # Import that source, avoiding ambient channels and user package settings.
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
in
# Reuse an existing package so pinning remains the only new concept.
pkgs.hello
