# The pinner owns fetching; expose short names for the teaching expression.
import ./nix/importer.nix {
    manifest = (import ./mana.nix) // { entrypoint = ./raw-sources.nix; };
  }
