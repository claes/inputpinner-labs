# Mana supplies raw pinned sources; flake-compat exposes the upstream overlay.
{ nixpkgs, patchelf, flake-compat }:
{ system ? builtins.currentSystem }:
let
  upstreamFlake = (import flake-compat { src = patchelf; inherit system; }).outputs;
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
