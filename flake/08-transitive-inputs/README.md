# 08 — Hello and patchelf share nixpkgs with flake (native)

Pin nixpkgs once. Use it for our own Hello and pass it to patchelf’s flake,
so its package output builds with the same chosen package set. This combines
the previous sharing exercises 08 and 10 into one comparison.

`inputs.patchelf.inputs.nixpkgs.follows = "nixpkgs"` shares the parent node
through upstream’s existing follows chains. No adapter library is needed.

Build directly with the included pins; no initializer or pinner CLI is needed:

```sh
nix build path:.#hello --out-link result-hello
nix build path:.#patchelf --out-link result-patchelf
./result-hello/bin/hello
./result-patchelf/bin/patchelf --version
readlink result-hello result-patchelf
```

Expect `Hello, world!` and `patchelf 0.19.2`.

In a disposable copy, change only the parent pin and rebuild:

```sh
./update.sh
nix build path:.#hello --out-link result-hello
nix build path:.#patchelf --out-link result-patchelf
readlink result-hello result-patchelf
```

`alternate-revision` selects the fixed older nixpkgs already recorded in
upstream’s lock. Both output paths change; patchelf’s source and version
stay fixed while its build environment changes. The seed file `revision`
stays unchanged, proving consumption follows the active pin.

The other six pinners have paired flake-compat and flake-inputs variants.
Adding either library here would duplicate the native resolver’s role.
See the [comparison table](../../README.md) for both alternatives.

All examples retain the same nixpkgs and patchelf snapshots. Keep native
declarations, locks, resolvers, revision seeds and versions in Git. To regenerate
the initial pins in another disposable copy, remove `flake.lock`, then run:

```sh
./init.sh
```

`../../verify-08.sh` checks all 14 native/library implementations in
fresh copies with spaces in their paths. Use `--syntax-only` for syntax checks or
`--updates` to test both parent pins.
See the [lab notes](../../README.md) for maintenance and Git configuration.
