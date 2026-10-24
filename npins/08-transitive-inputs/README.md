# 08: Share transitive inputs with npins

Keep the patchelf snapshot from 06–07 and make its package output use the parent
nixpkgs pin:

```sh
nix-build
./result/bin/patchelf-demo --version
```

Expect `patchelf 0.19.2`. This retains 06’s wrapper and package-output
interface. The new step shares the upstream input graph, rather than applying
07’s overlay.

The source resolver is unchanged from 06. The consumer reads the active revision
from `npins/sources.json` and passes it with the resolved sources to
`share-nixpkgs.nix`.

The helper writes a derived upstream tree with one replaced lock node. Its
revision comes from the real pin record, and its hash comes from the resolved
source; initialization seed files do not control this replacement.

Alternative considered: Adding a native `builtins.getFlake` remote reference
would create another pinning route. The derived lock instead uses metadata from
the manager’s active pin.

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
