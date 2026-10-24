# 08: Share transitive inputs with nixtamal

Keep the patchelf snapshot from 06–07 and make its package output use the parent
nixpkgs pin:

```sh
nix-build
./result/bin/patchelf-demo --version
```

Expect `patchelf 0.19.2`. This retains 06’s wrapper and package-output
interface. The new step shares the upstream input graph, rather than applying
07’s overlay.

The Nixtamal pins remain unchanged. The consumer reads the active freshness
value from `nix/tamal/lock.json`, then uses the shared-lock helper and existing
flake-compat dependency.

The helper targets this fixture’s version-7 upstream flake lock and its GitHub
nixpkgs node. The Nixtamal source lock remains authoritative; the transformation
is explicit consumer code.

Alternative considered: Embedding the replacement in the generated resolver
would be overwritten on regeneration. Keeping the helper beside the consumer
preserves the boundary between pinning and flake evaluation.

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
