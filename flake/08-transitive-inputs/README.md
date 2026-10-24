# 08: Share transitive inputs with flake

Keep the patchelf snapshot from 06–07 and make its package output use the parent
nixpkgs pin:

```sh
nix build path:.
./result/bin/patchelf-demo --version
```

Expect `patchelf 0.19.2`. This retains 06’s wrapper and package-output
interface. The new step shares the upstream input graph, rather than applying
07’s overlay.

`patchelf.inputs.nixpkgs.follows = "nixpkgs"` makes upstream reuse the parent’s
input node. The wrapper still consumes `patchelf.packages.${system}.default`, as
in 06.

The parent lock records a follows edge instead of a second nixpkgs node.
Upstream’s existing follows chains also reach the parent, including its
development-input aliases.

Alternative considered: Applying the overlay, as in 07, changes package
construction without sharing this graph. Overriding upstream with a second
identical URL would duplicate the pin declaration instead of reusing the parent
node.

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
