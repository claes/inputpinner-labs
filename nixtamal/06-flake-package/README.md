# 06: Consume a flake package with nixtamal

Build our `patchelf-demo` program using [NixOS/patchelf’s flake
output](https://github.com/NixOS/patchelf/blob/3e996dbef1fa0658012f8dd290bddcf0302acade/flake.nix),
then run it:

```sh
nix-build
./result/bin/patchelf-demo --version
```

The expected output is `patchelf 0.19.2`. The wrapper forwards arguments to the
upstream executable; interpolation records that package as a runtime dependency.

Nixtamal pins three immutable archives. Its resolver supplies source paths to
the parent nixpkgs import and to flake-compat, which evaluates patchelf’s flake
package.

Explicit freshness values reproduce the selected commits. The upstream flake
retains its own lock; the consumer’s nixpkgs is used only to create the wrapper.

Alternative considered: Nixtamal also supports build-time archive fetching,
which needs a bootstrap package set. Evaluation-time fetching suffices here and
makes the source-to-flake adapter boundary direct.

All locks and generated resolvers are included; builds need no initializer or
pinner CLI. `revision` and `patchelf-revision` seed initialization. The
source-only variants also pin
[flake-compat](https://github.com/NixOS/flake-compat/tree/5edf11c44bc78a0d334f6334cdaf7d60d732daab)
with `flake-compat-revision`. Updating these parent pins does not independently
refresh patchelf’s child lock. This example preserves that lock; sharing the
parent package set belongs to example 08.

To reproduce initialization, use a disposable copy without `nix/tamal/`:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#nixtamal.bin --command ./init.sh
```

`versions.txt` records maintenance tools. Manual initialization also needs jq.
The upstream output supports `x86_64-linux`, `i686-linux`, and `aarch64-linux`;
the lab verifies `x86_64-linux`. `../../verify-06.sh` compares source hashes,
upstream locks, package dependencies, wrapper derivations, and version output
across approaches, including fresh copies in paths with spaces.
