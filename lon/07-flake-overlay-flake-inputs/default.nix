{ system ? builtins.currentSystem }:
let
  sources = import ./lon.nix;
  # Evaluate the pinned flake source with its original upstream lock.
  upstreamFlake = (import sources.flake-inputs).import-flake { src = sources.patchelf; };
  upstreamOverlay = upstreamFlake.overlays.default;
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
