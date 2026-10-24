# Lab integration: adapt native source records to unflake's npins backend shape.
# No fetching or flake evaluation is reimplemented here. Read active revisions
# so a parent-only update also reaches every deduplicated nixpkgs input.
let
  sources = import ./sources.nix;
  names = builtins.fromJSON (builtins.readFile ./source-map.json);
  lock = builtins.fromJSON (builtins.readFile ./lon.lock);
  revisions = builtins.mapAttrs (_: pin: pin.revision) lock.sources;
in builtins.listToAttrs (map (name: {
  name = names.${name};
  value = { outPath = toString sources.${name}; revision = revisions.${name}; };
}) (builtins.attrNames names))
