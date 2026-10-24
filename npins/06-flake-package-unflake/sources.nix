# The pinner owns fetching; expose short names for the teaching expression.
let
    pins = import ./npins;
    names = builtins.fromJSON (builtins.readFile ./source-map.json);
  in builtins.mapAttrs (_: name: pins.${name}) names
