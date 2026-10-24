# 07 — Apply an upstream flake overlay with lon and flake-inputs

Obtain upstream’s `overlays.default` and apply it when importing the
parent nixpkgs. The overlay adds `pkgs.patchelf-new`; its recipe builds
with the parent’s compiler, libraries and helpers.

lon resolves nixpkgs, patchelf and the separately pinned flake-inputs source. The
adapter evaluates the upstream flake with its original lock; no input override or
lock rewrite is applied.

```nix
upstreamFlake = (import sources.flake-inputs).import-flake { src = sources.patchelf; };
```

Select `upstreamFlake.overlays.default`, then pass it through
`overlays = [ ... ];` to the parent import. This is recipe composition;
upstream’s locked nixpkgs remains unchanged.

Evaluation needs no import-from-derivation.

Build directly with the included pins; no initializer or pinner CLI is needed:

```sh
nix-build
./result/bin/patchelf --version
```

Expect `patchelf 0.19.2`. The attribute is named `patchelf-new`,
but its executable remains `bin/patchelf`. The original parent `patchelf`
is unchanged.

Compare the [flake-compat variant](../07-flake-overlay-flake-compat/README.md):
it preserves the same source pins, upstream graph and package behavior,
changing only the adapter and its call.

Native flake evaluation is used in the flake and tack references. An
input-sharing override would change the upstream graph and belongs to 08.
Selecting a package output instead would preserve its upstream build environment (06).

All examples retain the same nixpkgs and patchelf snapshots. Keep native
declarations, locks, resolvers, revision seeds and versions in Git. To regenerate
the initial pins in another disposable copy, remove `lon.lock` and `lon.nix`, then run:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#lon --command ./init.sh
```

`../../verify-07.sh` checks all 14 native/library implementations in
fresh copies with spaces in their paths. Use `--syntax-only` for syntax checks.
See the [lab notes](../../README.md) for maintenance and Git configuration.
