# 04: Selective updates with lon

Build Hello from two independent nixpkgs snapshots, then advance only unstable.

Lon 0.8.0 stores two GitHub branch sources in `lon.lock`. The generated
`lon.nix` resolver exposes both for separate imports.

`lon update unstable` selects one source. Initialization records explicit
commits while retaining their branch targets.

```sh
nix-build -A stable -o result-stable
nix-build -A unstable -o result-unstable
./result-stable/bin/hello
./result-unstable/bin/hello
```

Locks and generated resolvers are included; building needs no initializer or
pinner CLI. Run maintenance in a disposable copy:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#lon --command ./update.sh
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

Alternative considered: Lon 1.0.0 was needed for the tarball in example 02. This
GitHub-only example uses the already established 0.8.0 interface without that
additional tool dependency.
