# 06: Consume a flake package with niv

Build our `patchelf-demo` program using [NixOS/patchelf’s flake
output](https://github.com/NixOS/patchelf/blob/3e996dbef1fa0658012f8dd290bddcf0302acade/flake.nix),
then run it:

```sh
nix-build
./result/bin/patchelf-demo --version
```

The expected output is `patchelf 0.19.2`. The wrapper forwards arguments to the
upstream executable; interpolation records that package as a runtime dependency.

niv pins the parent nixpkgs, patchelf’s source, and flake-compat’s source. The
adapter evaluates the upstream flake; its `outputs.packages.${system}.default`
becomes a dependency of our wrapper.

Fetching a repository containing `flake.nix` does not itself evaluate its
outputs. The separately pinned adapter reads patchelf’s own `flake.lock`,
retaining its dependency graph.

Alternative considered: A direct `builtins.getFlake` call could use Nix’s flake
machinery but would bypass the niv source at this boundary. The adapter visibly
consumes the source resolved by niv.

All locks and generated resolvers are included; builds need no initializer or
pinner CLI. `revision` and `patchelf-revision` seed initialization. The
source-only variants also pin
[flake-compat](https://github.com/NixOS/flake-compat/tree/5edf11c44bc78a0d334f6334cdaf7d60d732daab)
with `flake-compat-revision`. Updating these parent pins does not independently
refresh patchelf’s child lock. This example preserves that lock; sharing the
parent package set belongs to example 08.

To reproduce initialization, use a disposable copy without `nix/`:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#niv --command ./init.sh
```

`versions.txt` records maintenance tools. Manual initialization also needs jq.
The upstream output supports `x86_64-linux`, `i686-linux`, and `aarch64-linux`;
the lab verifies `x86_64-linux`. `../../verify-06.sh` compares source hashes,
upstream locks, package dependencies, wrapper derivations, and version output
across approaches, including fresh copies in paths with spaces.
