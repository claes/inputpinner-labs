# 06: flake-package with mana and with-inputs

Build a parent-owned wrapper around the upstream patchelf package output.

```sh
nix-build -A patchelf-demo
./result/bin/patchelf-demo --version
```

The checked-in native pins and resolver suffice for builds. `init.sh` recreates
those records in a fresh copy using mana; it refuses to overwrite them.
Remove `lock.json` and `nix/` only in that disposable copy before reinitializing.
The revision seed files make that initialization repeatable. `versions.txt`
records the tools used. No pinner CLI is needed during ordinary evaluation.

[with-inputs](https://github.com/denful/with-inputs/tree/641d01ef95eae1aeaa257ffd48102ab9a308f2a2)
evaluates flake outputs from a flat set of prefetched sources. mana owns
all fetching and hashes, including the adapter, flake-parts and git-hooks-nix.
Source records retain their metadata; bare paths get an `outPath` wrapper.

The four-source scope uses a separately pinned `upstream-nixpkgs` matching
patchelf's original lock. Keeping the parent out of this scope prevents automatic
name matching from sharing it accidentally. The overlay still receives the
parent package set when applied in example 07.

Aliases `nixpkgs-lib` and `nixpkgs-stable` use the scoped nixpkgs too. Empty
follows for gitignore and flake-compat reproduce upstream's disconnected optional
development inputs. This deliberately supplies the graph needed for package and
overlay consumption; it does not reproduce upstream development checks.

Alternatives: the library's `from.flake` helper could fetch from a flake lock,
but this example keeps fetching under the native pinner. Sibling flake-compat,
flake-inputs and unflake variants show other evaluation approaches. This variant
needs no generated evaluator, source ID mapping, or second pinner.

Mana maintenance runs in a path without spaces due to its CLI path handling;
consuming the shipped pins also works in paths containing spaces.
