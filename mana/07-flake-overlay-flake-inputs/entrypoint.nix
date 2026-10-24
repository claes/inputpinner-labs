# Mana supplies raw pinned sources; flake-inputs exposes the upstream overlay.
{ nixpkgs, patchelf, flake-inputs }:
{ system ? builtins.currentSystem }:
let
  upstreamFlake = (import flake-inputs).import-flake { src = patchelf; };
  # Apply the recipe to the parent package set, preserving upstream's own lock.
  pkgs = import nixpkgs {
    inherit system;
    config = {};
    overlays = [ upstreamFlake.overlays.default ];
  };
in
{
  # The new attribute selects a package whose executable remains bin/patchelf.
  patchelf-new = pkgs.patchelf-new;
}
