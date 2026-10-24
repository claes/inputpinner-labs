# 04: Selective updates with manual

Build Hello from two independent nixpkgs snapshots, then advance only unstable.

`pins.json` contains two branch names, commit archive URLs, and unpacked hashes.
`default.nix` fetches only those immutable URLs and imports each source
separately.

`update.sh` resolves unstable’s branch, checks the commit format, prefetches its
hash, and replaces only `.unstable` with jq. It writes a temporary file before
replacing the lock.

```sh
nix-build -A stable -o result-stable
nix-build -A unstable -o result-unstable
./result-stable/bin/hello
./result-unstable/bin/hello
```

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
Manual maintenance also needs Git and jq.

Alternative considered: Updating the entire JSON document from fresh branch
lookups could advance stable too. A named entry replacement makes the
preservation requirement explicit without an extra pinning library.
