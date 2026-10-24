# 04: Selective updates with tack

Build Hello from two independent nixpkgs snapshots, then advance only unstable.

Two source-only GitHub pins are declared in `.tack/pins.toml`;
`.tack/pins.lock.json` supplies commits and hashes to the generated resolver.

`tack update unstable` updates the named pin. Initialization locks commit URLs
before restoring branch URLs as future update targets.

```sh
nix-build -A stable -o result-stable
nix-build -A unstable -o result-unstable
./result-stable/bin/hello
./result-unstable/bin/hello
```

Locks and generated resolvers are included; building needs no initializer or
pinner CLI. Run maintenance in a disposable copy:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#tack --command ./update.sh
# Repeat the two build commands above.
```

Compare the lock before and after: unstable's commit and hash should change;
stable's entire entry and Hello derivation should stay unchanged. Both programs
print `Hello, world!`. Updating nixpkgs need not change Hello's version.
`../../verify-04.sh --updates` checks these properties across all approaches;
see the root README for its maintenance environment.

The `stable-revision` and `unstable-revision` files seed initialization only.
Stable starts at `2efa67fd26b6df417c33e4603185c701f260dd83`; unstable starts at
`34ab99075ac4f7e40cf037eef32cb1c360bb85e9`. The unstable seed is older, leaving
room for an observable branch update. Branch targets are `nixos-26.05` and
`nixpkgs-unstable` respectively. Builds use active locks.

To reproduce initialization, use a new copy without its generated lock/resolver
files and run `./init.sh` with the same maintenance tool environment as above
(replace `./update.sh` with `./init.sh`). `versions.txt` records the tools used.

Alternative considered: tack can consume upstream flake outputs, but source-only
pins make the two nixpkgs imports explicit here. No flake adapter is needed.
