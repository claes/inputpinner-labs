# flake-compat has no lock/input override argument in our pinned revision.
# Stage a derived source tree whose existing follows edges reach the parent pin.
{ pkgs, nixpkgsSource, parentRevision, patchelfSource }:
let
  lock = builtins.fromJSON (builtins.readFile (patchelfSource + "/flake.lock"));
  nixpkgsNode = lock.nodes.${lock.root}.inputs.nixpkgs;
  # Derive this hash from the pinner-resolved tree, avoiding a second remote pin.
  parentTree = builtins.fetchTree { type = "path"; path = toString nixpkgsSource; };
  sharedLock = lock // {
    nodes = lock.nodes // {
      ${nixpkgsNode} = lock.nodes.${nixpkgsNode} // {
        # Re-express this fixture's GitHub pin using the manager's active revision
        # and the hash of its resolved tree; no store path enters the JSON.
        locked = {
          type = "github";
          owner = "NixOS";
          repo = "nixpkgs";
          rev = parentRevision;
          narHash = parentTree.narHash;
        };
      };
    };
  };
  lockFile = pkgs.writeText "shared-flake.lock" (builtins.toJSON sharedLock);
in
assert lock.version == 7;
assert builtins.isString nixpkgsNode;
# Importing the result builds this copy during evaluation (IFD).
# The original pinned tree and the project's lock remain untouched.
pkgs.runCommand "patchelf-with-shared-nixpkgs" {} ''
  mkdir -p "$out"
  cp -R ${patchelfSource}/. "$out/"
  chmod u+w "$out/flake.lock"
  cp ${lockFile} "$out/flake.lock"
''
