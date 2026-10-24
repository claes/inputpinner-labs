# 08 — Hello and patchelf share nixpkgs with tack (native)

Pin nixpkgs once. Use it for our own Hello and pass it to patchelf’s flake,
so its package output builds with the same chosen package set. This combines
the previous sharing exercises 08 and 10 into one comparison.

The `[all_follow]` rule shares the parent nixpkgs flake, including `nixpkgs-lib`
and `nixpkgs-stable` aliases. It is a name-based rule applied at every depth;
review it when adding inputs. No adapter library is needed.

Build directly with the included pins; no initializer or pinner CLI is needed:

```sh
nix-build -A hello -o result-hello
nix-build -A patchelf -o result-patchelf
./result-hello/bin/hello
./result-patchelf/bin/patchelf --version
readlink result-hello result-patchelf
```

Expect `Hello, world!` and `patchelf 0.19.2`.

In a disposable copy, change only the parent pin and rebuild:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#tack --command ./update.sh
nix-build -A hello -o result-hello
nix-build -A patchelf -o result-patchelf
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
the initial pins in another disposable copy, remove `.tack/`, then run:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#tack --command ./init.sh
```

`../../verify-08.sh` checks all 14 native/library implementations in
fresh copies with spaces in their paths. Use `--syntax-only` for syntax checks or
`--updates` to test both parent pins.
See the [lab notes](../../README.md) for maintenance and Git configuration.
