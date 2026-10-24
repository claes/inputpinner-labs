# 06: Consume a flake package with mana

Build our `patchelf-demo` program using [NixOS/patchelf’s flake
output](https://github.com/NixOS/patchelf/blob/3e996dbef1fa0658012f8dd290bddcf0302acade/flake.nix),
then run it:

```sh
nix-build -A patchelf-demo
./result/bin/patchelf-demo --version
```

The expected output is `patchelf 0.19.2`. The wrapper forwards arguments to the
upstream executable; interpolation records that package as a runtime dependency.

Mana fetches three raw dependencies with `entrypoint = null`. The entrypoint
imports flake-compat to evaluate patchelf’s output and passes its package path
into our wrapper.

The pinned Mana importer does not automatically evaluate an upstream flake. The
adapter reads patchelf’s own lock. Normal builds need no Mana CLI; its
initialization limitation for paths containing spaces still applies.

Alternative considered: A custom dependency entrypoint could hide the adapter
inside Mana’s import machinery. Keeping the conversion in our entrypoint makes
the source-to-flake boundary visible.

All locks and generated resolvers are included; builds need no initializer or
pinner CLI. `revision` and `patchelf-revision` seed initialization. The
source-only variants also pin
[flake-compat](https://github.com/NixOS/flake-compat/tree/5edf11c44bc78a0d334f6334cdaf7d60d732daab)
with `flake-compat-revision`. Updating these parent pins does not independently
refresh patchelf’s child lock. This example preserves that lock; sharing the
parent package set belongs to example 08.

To reproduce initialization, use a disposable copy without `lock.json and nix/`:

```sh
./init.sh
```

`versions.txt` records maintenance tools. Manual initialization also needs jq.
The upstream output supports `x86_64-linux`, `i686-linux`, and `aarch64-linux`;
the lab verifies `x86_64-linux`. `../../verify-06.sh` compares source hashes,
upstream locks, package dependencies, wrapper derivations, and version output
across approaches, including fresh copies in paths with spaces.
