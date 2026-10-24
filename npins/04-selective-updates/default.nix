{ system ? builtins.currentSystem }:
let
  sources = import ./npins;
  # Import each package set separately; neither inherits the other's packages.
  stablePkgs = import sources.stable { inherit system; config = {}; overlays = []; };
  unstablePkgs = import sources.unstable { inherit system; config = {}; overlays = []; };
in
{
  stable = stablePkgs.hello;
  unstable = unstablePkgs.hello;
}
