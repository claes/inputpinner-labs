{ system ? builtins.currentSystem }:
let
  sources = import ./sources.nix;
  # The generated evaluator injects pinner-fetched sources into upstream flakes.
  upstream = (import ./unflake.nix).patchelf;
  # Unflake's deduplication rules route upstream nixpkgs edges to this source.
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
in
{
  hello = pkgs.hello;
  patchelf = upstream.packages.${system}.default;
}
