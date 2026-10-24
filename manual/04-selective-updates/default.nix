{ system ? builtins.currentSystem }:
let
  sources = builtins.mapAttrs (_: pin: builtins.fetchTarball {
    inherit (pin) url sha256;
  }) (builtins.fromJSON (builtins.readFile ./pins.json));
  # Import each package set separately; neither inherits the other's packages.
  stablePkgs = import sources.stable { inherit system; config = {}; overlays = []; };
  unstablePkgs = import sources.unstable { inherit system; config = {}; overlays = []; };
in
{
  stable = stablePkgs.hello;
  unstable = unstablePkgs.hello;
}
