# 07 — Apply an upstream flake overlay with tack (native)

Obtain upstream’s `overlays.default` and apply it when importing the
parent nixpkgs. The overlay adds `pkgs.patchelf-new`; its recipe builds
with the parent’s compiler, libraries and helpers.

Tack’s native flake pin exposes the upstream outputs. No adapter library is
needed.

Build directly with the included pins; no initializer or pinner CLI is needed:

```sh
nix-build
./result/bin/patchelf --version
```

Expect `patchelf 0.19.2`. The attribute is named `patchelf-new`,
but its executable remains `bin/patchelf`. The original parent `patchelf`
is unchanged.

The other six pinners have paired flake-compat and flake-inputs variants.
Adding either library here would duplicate the native resolver’s role.
See the [comparison table](../../README.md) for both alternatives.

All examples retain the same nixpkgs and patchelf snapshots. Keep native
declarations, locks, resolvers, revision seeds and versions in Git. To regenerate
the initial pins in another disposable copy, remove `.tack/`, then run:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#tack --command ./init.sh
```

`../../verify-07.sh` checks all 14 native/library implementations in
fresh copies with spaces in their paths. Use `--syntax-only` for syntax checks.
See the [lab notes](../../README.md) for maintenance and Git configuration.
