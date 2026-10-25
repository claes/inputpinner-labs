# Expose the system explicitly so the same pins can be used on another platform.
{ system ? builtins.currentSystem }:
let
  sources = import ./nix/tamal { inherit system; };
  # Separate package sets let an unstable-only update leave stable's package unchanged.
  # Empty config and overlays exclude personal Nixpkgs settings from this example.
  stablePkgs = import sources.stable { inherit system; config = {}; overlays = []; };
  unstablePkgs = import sources.unstable { inherit system; config = {}; overlays = []; };
in
{
  stable = stablePkgs.hello;
  unstable = unstablePkgs.hello;
}
