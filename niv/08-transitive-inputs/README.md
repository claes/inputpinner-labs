# 08: Share transitive inputs with niv

Keep the patchelf snapshot from 06–07 and make its package output use the parent
nixpkgs pin:

```sh
nix-build
./result/bin/patchelf-demo --version
```

Expect `patchelf 0.19.2`. This retains 06’s wrapper and package-output
interface. The new step shares the upstream input graph, rather than applying
07’s overlay.

niv still pins the three source trees from 06. The consumer reads the active
`sources.nixpkgs.rev`, then `share-nixpkgs.nix` adapts upstream’s lock before
flake-compat evaluates its outputs.

The native source pin is unchanged. The helper reconstructs this fixture’s
GitHub lock record from that revision and the resolved tree hash, replacing the
node used by existing upstream follows paths.

Alternative considered: Re-evaluating only upstream’s outputs with a replacement
direct argument was considered, but would leave other follows chains using the
old package set. A derived lock copy lets the existing adapter resolve the whole
graph.

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
