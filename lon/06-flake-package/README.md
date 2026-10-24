# 06: Consume a flake package with lon

Build our `patchelf-demo` program using [NixOS/patchelf’s flake
output](https://github.com/NixOS/patchelf/blob/3e996dbef1fa0658012f8dd290bddcf0302acade/flake.nix),
then run it:

```sh
nix-build
./result/bin/patchelf-demo --version
```

The expected output is `patchelf 0.19.2`. The wrapper forwards arguments to the
upstream executable; interpolation records that package as a runtime dependency.

Lon 0.8.0 resolves the parent nixpkgs, patchelf, and flake-compat sources. The
adapter evaluates patchelf’s outputs, and our wrapper executes its default
package.

The generated Lon resolver returns sources rather than flake output sets. The
compatibility adapter preserves the upstream lock and keeps fetching separate
from evaluating outputs.

Alternative considered: Lon 1.0.0 was needed for example 02’s archive URL. This
GitHub-only example works with 0.8.0; a tool upgrade would not remove the
adapter step used here.

All locks and generated resolvers are included; builds need no initializer or
pinner CLI. `revision` and `patchelf-revision` seed initialization. The
source-only variants also pin
[flake-compat](https://github.com/NixOS/flake-compat/tree/5edf11c44bc78a0d334f6334cdaf7d60d732daab)
with `flake-compat-revision`. Updating these parent pins does not independently
refresh patchelf’s child lock. This example preserves that lock; sharing the
parent package set belongs to example 08.

To reproduce initialization, use a disposable copy without `lon.lock and
lon.nix`:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#lon --command ./init.sh
```

`versions.txt` records maintenance tools. Manual initialization also needs jq.
The upstream output supports `x86_64-linux`, `i686-linux`, and `aarch64-linux`;
the lab verifies `x86_64-linux`. `../../verify-06.sh` compares source hashes,
upstream locks, package dependencies, wrapper derivations, and version output
across approaches, including fresh copies in paths with spaces.
