# 08: Share transitive inputs with mana

Keep the patchelf snapshot from 06–07 and make its package output use the parent
nixpkgs pin:

```sh
nix-build -A patchelf-demo
./result/bin/patchelf-demo --version
```

Expect `patchelf 0.19.2`. This retains 06’s wrapper and package-output
interface. The new step shares the upstream input graph, rather than applying
07’s overlay.

Mana still supplies raw dependencies. The entrypoint reads the active nixpkgs
revision from `lock.json`, adapts upstream’s lock, and obtains its package
output through the existing flake-compat pin.

Mana’s `shares` mechanism applies to Mana dependency graphs; it does not rewrite
this raw upstream flake’s internal inputs. The adaptation explicitly handles
that separate graph.

Alternative considered: Supplying a different direct entrypoint could hide the
transformation, but would not make it native flake sharing. The helper exposes
both the changed node and the evaluation cost.

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
a disposable copy without its generated files. Mana maintenance still needs a
path without spaces.

`../../verify-08.sh` checks source hashes, effective direct and transitive
inputs, parent build dependencies, matching packages and wrappers, and unchanged
files in fresh copies with spaces in their paths. The READMEs and root
comparison describe the different costs of native and adapted graph sharing.
