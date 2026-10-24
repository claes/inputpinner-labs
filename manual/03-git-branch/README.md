# 03 — A Git branch with Manual baseline

## Goal and approach

Track `nix-systems/default` on `main`, while consuming a locked commit.

`pins.json` stores the update branch separately from the commit-specific URL and tree hash. Builds import that URL; the updater resolves the branch and rewrites only its pin.

## Main challenges

Do not fetch `main.tar.gz` during evaluation. Resolve the branch explicitly, validate the commit, and calculate its hash before replacing the record.

## Alternatives considered

`builtins.fetchGit` could consume the locked revision directly. Commit archives match the source approach used by the other examples and keep hashes explicit.

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
./update.sh
nix-build
cat result
```

At validation time, main had removed `x86_64-darwin`. Rebuilding alone keeps the
old list; updating changes the systems lock and leaves nixpkgs fixed.
The updater additionally needs Git, jq, and nix-prefetch-url. See the [lab Git configuration notes](../../README.md) if a public HTTPS
lookup is rewritten to SSH.

To reproduce the initial pins in a copy without generated pinning files:

```sh
./init.sh
```

Keep locks, resolvers, and `versions.txt` in version control. `verify-03.sh`
checks the shipped historical snapshot, so it intentionally fails after updates.
