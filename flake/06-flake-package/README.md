# 06 — Consume an upstream flake package with flake (native)

Build `patchelf-demo`, a wrapper around upstream’s
`packages.<system>.default`. The parent nixpkgs creates the wrapper;
patchelf keeps the nixpkgs selected by its own upstream lock.

A native flake input exposes the upstream outputs. No adapter library is needed.

Build directly with the included pins; no initializer or pinner CLI is needed:

```sh
nix build path:.
./result/bin/patchelf-demo --version
```

Expect `patchelf 0.19.2`.

The other six pinners have flake-compat, flake-inputs and unflake variants.
Adding either library here would duplicate the native resolver’s role.
See the [comparison table](../../README.md) for these alternatives.

All examples retain the same nixpkgs and patchelf snapshots. Keep native
declarations, locks, resolvers, revision seeds and versions in Git. To regenerate
the initial pins in another disposable copy, remove `flake.lock`, then run:

```sh
./init.sh
```

`../../verify-06.sh` checks all 20 native/library/unflake implementations in
fresh copies with spaces in their paths. Use `--syntax-only` for syntax checks.
See the [lab notes](../../README.md) for maintenance and Git configuration.
