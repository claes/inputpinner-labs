{ system ? builtins.currentSystem }:
let
  sources = import ./.tack;
  # all_follow gives upstream the same nixpkgs flake that supplies our Hello.
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
in
{
  hello = pkgs.hello;
  patchelf = sources.patchelf.packages.${system}.default;
}
