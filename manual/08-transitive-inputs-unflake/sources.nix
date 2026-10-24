# The pinner owns fetching; expose short names for the teaching expression.
builtins.mapAttrs (_: pin: builtins.fetchTarball {
    inherit (pin) url sha256;
  }) (builtins.fromJSON (builtins.readFile ./pins.json))
