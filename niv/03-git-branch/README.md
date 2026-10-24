# 03 — A Git branch with niv

## Goal and approach

Track `nix-systems/default` on `main`, while consuming a locked commit.

The systems record has `branch = "main"` for updates and a separate `rev` and hash for consumption. The generated resolver fetches that commit, whose list becomes the text file.

## Main challenges

Pass the branch and starting revision separately, then use `niv update systems` to refresh that input.

## Alternatives considered

niv supports experimental generic Git inputs. Its normal GitHub source expresses this branch workflow without that extra mechanism.

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
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#niv --command ./update.sh
nix-build
cat result
```

At validation time, main had removed `x86_64-darwin`. Rebuilding alone keeps the
old list; updating changes the systems lock and leaves nixpkgs fixed.
Nix with `nix-command` and `flakes` is needed for the maintenance commands. See the [lab Git configuration notes](../../README.md) if a public HTTPS
lookup is rewritten to SSH.

To reproduce the initial pins in a copy without generated pinning files:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#niv --command ./init.sh
```

Keep locks, resolvers, and `versions.txt` in version control. `verify-03.sh`
checks the shipped historical snapshot, so it intentionally fails after updates.
