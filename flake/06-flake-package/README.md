# 06: Consume a flake package with flake

Build our `patchelf-demo` program using [NixOS/patchelf’s flake
output](https://github.com/NixOS/patchelf/blob/3e996dbef1fa0658012f8dd290bddcf0302acade/flake.nix),
then run it:

```sh
nix build path:.
./result/bin/patchelf-demo --version
```

The expected output is `patchelf 0.19.2`. The wrapper forwards arguments to the
upstream executable; interpolation records that package as a runtime dependency.

A native flake input provides `patchelf.packages.${system}.default`. The
parent’s separately pinned nixpkgs creates `patchelf-demo`, a shell wrapper that
executes that upstream package.

Nix records patchelf’s input graph in the parent lock. No `follows` override is
applied, so upstream retains its own nixpkgs and other locked dependencies.

Alternative considered: A pinned flake-compat adapter is used by the source-only
examples. Native flake evaluation already provides the needed outputs here, so
the adapter and flake utility libraries are unnecessary.

All locks and generated resolvers are included; builds need no initializer or
pinner CLI. `revision` and `patchelf-revision` seed initialization. The
source-only variants also pin
[flake-compat](https://github.com/NixOS/flake-compat/tree/5edf11c44bc78a0d334f6334cdaf7d60d732daab)
with `flake-compat-revision`. Updating these parent pins does not independently
refresh patchelf’s child lock. This example preserves that lock; sharing the
parent package set belongs to example 08.

To reproduce initialization, use a disposable copy without `flake.lock`:

```sh
./init.sh
```

`versions.txt` records maintenance tools. Manual initialization also needs jq.
The upstream output supports `x86_64-linux`, `i686-linux`, and `aarch64-linux`;
the lab verifies `x86_64-linux`. `../../verify-06.sh` compares source hashes,
upstream locks, package dependencies, wrapper derivations, and version output
across approaches, including fresh copies in paths with spaces.
