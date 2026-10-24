# 06 — Consume an upstream flake package with lon and flake-inputs

Build `patchelf-demo`, a wrapper around upstream’s
`packages.<system>.default`. The parent nixpkgs creates the wrapper;
patchelf keeps the nixpkgs selected by its own upstream lock.

lon resolves nixpkgs, patchelf and the separately pinned flake-inputs source. The
adapter evaluates the upstream flake with its original lock; no input override or
lock rewrite is applied.

```nix
upstreamFlake = (import sources.flake-inputs).import-flake { src = sources.patchelf; };
```

Select `upstreamFlake.packages.${system}.default` and interpolate its
executable into the wrapper. That records the package as a runtime dependency
and forwards arguments to it.

Evaluation needs no import-from-derivation.

Build directly with the included pins; no initializer or pinner CLI is needed:

```sh
nix-build
./result/bin/patchelf-demo --version
```

Expect `patchelf 0.19.2`.

Compare the [flake-compat variant](../06-flake-package-flake-compat/README.md):
it preserves the same source pins, upstream graph and package behavior,
changing only the adapter and its call.

Native flake evaluation is used in the flake and tack references. An
input-sharing override would change the upstream graph and belongs to 08.
Using an overlay would instead rebuild the recipe in the parent package set (07).

All examples retain the same nixpkgs and patchelf snapshots. Keep native
declarations, locks, resolvers, revision seeds and versions in Git. To regenerate
the initial pins in another disposable copy, remove `lon.lock` and `lon.nix`, then run:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#lon --command ./init.sh
```

`../../verify-06.sh` checks all 14 native/library implementations in
fresh copies with spaces in their paths. Use `--syntax-only` for syntax checks.
See the [lab notes](../../README.md) for maintenance and Git configuration.
