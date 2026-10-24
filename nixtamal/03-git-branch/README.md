# 03 — A Git branch with Nixtamal

## Goal and approach

Track `nix-systems/default` on `main`, while consuming a locked commit.

A freshness command resolves `refs/heads/main`; the archive URL uses that commit. The lock stores the resolved URL/hash, and normal evaluation imports the stored source.

## Main challenges

Initialize with the historical freshness value, lock it, then switch the manifest command to the main-branch lookup. Refreshing systems later changes its lock.

## Alternatives considered

A Git input could fetch a checkout. An archive plus a visible freshness command exposes Nixtamal's distinction between choosing a revision and consuming it.

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
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#nixtamal.bin --command ./update.sh
nix-build
cat result
```

At validation time, main had removed `x86_64-darwin`. Rebuilding alone keeps the
old list; updating changes the systems lock and leaves nixpkgs fixed.
Nix with `nix-command` and `flakes` is needed for the maintenance commands. See the [lab Git configuration notes](../../README.md) if a public HTTPS
lookup is rewritten to SSH.

To reproduce the initial pins in a copy without generated pinning files:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#nixtamal.bin --command ./init.sh
```

Keep locks, resolvers, and `versions.txt` in version control. `verify-03.sh`
checks the shipped historical snapshot, so it intentionally fails after updates.
