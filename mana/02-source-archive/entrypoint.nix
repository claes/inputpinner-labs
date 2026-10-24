# Mana injects the package-set source and the application's source separately.
{ nixpkgs, hello }:
{ system ? builtins.currentSystem }:
let
  pkgs = import nixpkgs { inherit system; config = {}; overlays = []; };
in
{
  # Only the source changes; retain the package's existing build recipe.
  hello = pkgs.hello.overrideAttrs (_: { src = hello; });
}
