# 03 — A Git branch with npins

## Goal and approach

Track `nix-systems/default` on `main`, while consuming a locked commit.

Add a systems GitHub pin with `--branch main` and `--at` the starting commit. Import its locked source and write the list to a file.

## Main challenges

The branch selects future revisions; `--at` seeds the lock once. `npins update systems` explicitly resolves the branch again.

## Alternatives considered

Tracking release tags is another npins workflow, but would demonstrate version selection instead of a moving branch. Generic Git fetching is unnecessary for this GitHub source.

## Build and update

With the included pins, build directly:

```sh
nix-build
cat result
```

The initial file lists `aarch64-darwin`, `aarch64-linux`, `x86_64-darwin`, and
`x86_64-linux`, one per line. It deliberately uses the historical four-system
snapshot recorded in `systems-revision`.

In a disposable copy, follow current main explicitly, then rebuild:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#npins --command ./update.sh
nix-build
cat result
```

At validation time, main had removed `x86_64-darwin`. Rebuilding alone keeps the
old list; updating changes the systems lock and leaves nixpkgs fixed.
Nix with `nix-command` and `flakes` is needed for the maintenance commands. See the [lab Git configuration notes](../../README.md) if a public HTTPS
lookup is rewritten to SSH.

To reproduce the initial pins in a copy without generated pinning files:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#npins --command ./init.sh
```

Keep locks, resolvers, and `versions.txt` in version control. `verify-03.sh`
checks the shipped historical snapshot, so it intentionally fails after updates.
