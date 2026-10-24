# 08: Share transitive inputs with tack

Keep the patchelf snapshot from 06–07 and make its package output use the parent
nixpkgs pin:

```sh
nix-build
./result/bin/patchelf-demo --version
```

Expect `patchelf 0.19.2`. This retains 06’s wrapper and package-output
interface. The new step shares the upstream input graph, rather than applying
07’s overlay.

The parent nixpkgs is now a flake pin so it supplies `lib` and `legacyPackages`.
An `all_follow` rule shares it at every depth, including inputs named
`nixpkgs-lib` and `nixpkgs-stable`.

A per-pin direct-input override would leave the resolver’s transitive aliases on
their original nodes. This fixture’s explicit alias list covers the upstream
graph. The global rule also applies to other matching input names if more pins
are added.

Alternative considered: A source-only parent pin lacks the outputs required by
the upstream flake. A source-only patchelf pin plus the staged compatibility
adapter would work, but native sharing avoids that extra evaluation build.

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
