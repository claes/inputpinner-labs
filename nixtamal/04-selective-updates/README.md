# 04: Selective updates with nixtamal

Build Hello from two independent nixpkgs snapshots, then advance only unstable.

Each named archive has a freshness command in `nix/tamal/manifest.kdl`. Refresh
resolves its branch to a commit, then hashes that immutable archive; evaluation
reads `lock.json`.

`nixtamal refresh --no-tui unstable` runs only that input’s refresh.
Initialization first seeds explicit commits, then installs the branch lookup
commands.

```sh
nix-build -A stable -o result-stable
nix-build -A unstable -o result-unstable
./result-stable/bin/hello
./result-unstable/bin/hello
```

Locks and generated resolvers are included; building needs no initializer or
pinner CLI. Run maintenance in a disposable copy:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#nixtamal.bin --command ./update.sh
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

Alternative considered: The built-in nixpkgs setup was investigated earlier but
did not honor the requested seed revision in 1.5.4. Explicit archives avoid that
ambiguity. Evaluation-time fetching also avoids a third bootstrap nixpkgs.
