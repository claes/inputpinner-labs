# 04: Selective updates with mana

Build Hello from two independent nixpkgs snapshots, then advance only unstable.

The manifest declares two raw dependencies with `entrypoint = null`. Its
generated importer passes the locked source paths to `entrypoint.nix`, which
imports each package set.

`mana update unstable` requests only one dependency. The pinned tool is invoked
through `tool-ref`. Initialization temporarily substitutes seed commits because
Mana has no CLI seed override.

```sh
nix-build -A stable -o result-stable
nix-build -A unstable -o result-unstable
./result-stable/bin/hello
./result-unstable/bin/hello
```

Source inspection also shows that the resolver fetches inputs when checking
source deduplication, including dependencies skipped by a named update. Selective
updating preserves stable's lock entry; it can still access stable's upstream.

The pinned Mana CLI passes its working directory as an unquoted Nix expression.
Run `init.sh` and `update.sh` from a path without spaces. Building from the saved
lock works in paths containing spaces. The verifier tests these cases separately;
a temporary-copy wrapper was considered but would obscure the native command.

Locks and generated resolvers are included; building needs no initializer or
pinner CLI. Run maintenance in a disposable copy:

```sh
./update.sh
# Repeat the two build commands above.
```

Compare the lock before and after: unstable's commit and hash should change;
stable's entire entry and Hello derivation should stay unchanged. Both programs
print `Hello, world!`. Updating nixpkgs need not change Hello's version.
`../../verify-04.sh --updates` checks these properties across all approaches;
see the root README for its maintenance environment.

`stable-revision` and `unstable-revision` seed initialization only. The unstable
seed is older, leaving room for an observable refresh. Branch targets are
`nixos-26.05` and `nixpkgs-unstable`. Builds use active locks.

To reproduce initialization, use a new copy without its generated lock/resolver
files and run `./init.sh` with the same maintenance tool environment as above
(replace `./update.sh` with `./init.sh`). `versions.txt` records the tools used.
Mana invokes its pinned tool itself.

Alternative considered: Mana can recursively consume Mana manifests. Raw
dependencies keep this example focused on independent package sets rather than
recursive resolution. No flake compatibility adapter is needed.
