# 08: Share transitive inputs with manual

Keep the patchelf snapshot from 06–07 and make its package output use the parent
nixpkgs pin:

```sh
nix-build
./result/bin/patchelf-demo --version
```

Expect `patchelf 0.19.2`. This retains 06’s wrapper and package-output
interface. The new step shares the upstream input graph, rather than applying
07’s overlay.

`pins.json` remains the source of revisions, URLs, and hashes. Its active
nixpkgs revision and resolved tree are passed to `share-nixpkgs.nix`, then
flake-compat evaluates the adapted upstream.

The helper replaces upstream’s existing nixpkgs lock node. The manager’s own
record and the original upstream source stay unchanged, while all incoming
follows paths reach the replacement.

Alternative considered: Copying the initialization revision into upstream’s lock
would become stale after a pin update. Reading the active record keeps sharing
tied to the actual parent pin.

The pinned flake-compat has no input/lock override parameter. The helper builds
a store copy containing the adapted lock, so evaluation requires
import-from-derivation (`allow-import-from-derivation = true`). No project files
are rewritten. It assumes this fixture’s GitHub nixpkgs pin and version-7 lock;
this is not a general flake resolver. Local overrides from 05 are a separate
case.

Source pins, seed revisions, and tool versions reuse 06. Original upstream
sources remain immutable. Flakes regenerate their parent lock with the follows
edge; tack changes its sharing declarations; the source-only managers retain
their existing locks and resolvers. Builds need no initialization or pinner CLI.
For regeneration, use this directory’s `init.sh` with 06’s maintenance setup in
a disposable copy without its generated files.  `../../verify-08.sh` checks
source hashes, effective direct and transitive inputs, parent build
dependencies, matching packages and wrappers, and unchanged files in fresh
copies with spaces in their paths. The READMEs and root comparison describe the
different costs of native and adapted graph sharing.
