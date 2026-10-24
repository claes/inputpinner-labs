# Mana injects the dependency named in mana.nix.
{ nixpkgs }:
{ system ? builtins.currentSystem }:
let
  # Keep importing the package set separate from resolving its source.
  pkgs = import nixpkgs { inherit system; config = {}; overlays = []; };
in
{
  # Mana's generated default.nix exposes this named result.
  hello = pkgs.hello;
}
