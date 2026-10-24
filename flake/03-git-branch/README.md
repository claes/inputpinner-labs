# 03 — A Git branch with Nix flakes

## Goal and approach

Track `nix-systems/default` on `main`, while consuming a locked commit.

The non-flake systems input declares `main`; `flake.lock` records its selected commit. Import the locked list and turn it into a text file.

## Main challenges

`--override-input` seeds the historical commit while the manifest retains `main`. Normal builds read the lock; only an explicit update follows the branch.

## Alternatives considered

A generic `git+https` input could fetch a Git checkout. The native GitHub input resolves the same branch with less fetching. No flake-output adapter is needed.

## Build and update

With the included pins, build directly:

```sh
nix build path:.
cat result
```

The initial file lists `aarch64-darwin`, `aarch64-linux`, `x86_64-darwin`, and
`x86_64-linux`, one per line. It deliberately uses the historical four-system
snapshot recorded in `systems-revision`.

In a disposable copy, follow current main explicitly, then rebuild:

```sh
./update.sh
nix build path:.
cat result
```

At validation time, main had removed `x86_64-darwin`. Rebuilding alone keeps the
old list; updating changes the systems lock and leaves nixpkgs fixed.
Nix with `nix-command` and `flakes` is needed for the maintenance commands. See the [lab Git configuration notes](../../README.md) if a public HTTPS
lookup is rewritten to SSH.

To reproduce the initial pins in a copy without generated pinning files:

```sh
./init.sh
```

Keep locks, resolvers, and `versions.txt` in version control. `verify-03.sh`
checks the shipped historical snapshot, so it intentionally fails after updates.
