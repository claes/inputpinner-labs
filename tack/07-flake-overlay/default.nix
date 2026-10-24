{ system ? builtins.currentSystem }:
let
  sources = import ./.tack;
  # A native flake pin exposes its outputs, including this overlay function.
  upstreamOverlay = sources.patchelf.overlays.default;
  # The overlay receives this parent package set and adds patchelf-new to it.
  # Its recipe now uses the parent's compiler, libraries, and build helpers.
  pkgs = import sources.nixpkgs {
    inherit system;
    config = {};
    overlays = [ upstreamOverlay ];
  };
in
# This is an attribute added by the overlay; the executable is still bin/patchelf.
pkgs.patchelf-new
