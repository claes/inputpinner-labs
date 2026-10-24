# 08: transitive-inputs with manual and with-inputs

Build parent `hello` and upstream `patchelf` using the same parent nixpkgs.

```sh
nix-build -A hello -o result-hello
nix-build -A patchelf -o result-patchelf
./result-hello/bin/hello
./result-patchelf/bin/patchelf --version
```

The checked-in native pins and resolver suffice for builds. `init.sh` recreates
those records in a fresh copy using `nix-prefetch-url` and jq; it refuses to overwrite them.
Remove `pins.json` only in that disposable copy before reinitializing.
The revision seed files make that initialization repeatable. `versions.txt`
records the tools used. No pinner CLI is needed during ordinary evaluation.

[with-inputs](https://github.com/denful/with-inputs/tree/641d01ef95eae1aeaa257ffd48102ab9a308f2a2)
evaluates flake outputs from a flat set of prefetched sources. manual owns
all fetching and hashes, including the adapter, flake-parts and git-hooks-nix.
Source records retain their metadata; bare paths get an `outPath` wrapper.

The four-source scope uses the parent nixpkgs. The explicit
`patchelf.inputs.nixpkgs.follows = "nixpkgs"` documents the sharing relationship.
Automatic matching by input name would also work, but would hide that decision.
Run `./update.sh` in a disposable copy to change only the parent pin to the fixed
alternate revision. Both package derivations then change; adapter and upstream
source pins stay fixed. The `revision` seed still records the initial pin.

Aliases `nixpkgs-lib` and `nixpkgs-stable` use the scoped nixpkgs too. Empty
follows for gitignore and flake-compat reproduce upstream's disconnected optional
development inputs. This deliberately supplies the graph needed for package and
overlay consumption; it does not reproduce upstream development checks.

Alternatives: the library's `from.flake` helper could fetch from a flake lock,
but this example keeps fetching under the native pinner. Sibling flake-compat,
flake-inputs and unflake variants show other evaluation approaches. This variant
needs no generated evaluator, source ID mapping, or second pinner.
