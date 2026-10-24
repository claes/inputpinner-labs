# 03 — A Git branch with Mana

## Goal and approach

Track `nix-systems/default` on `main`, while consuming a locked commit.

The manifest declares a raw systems dependency at `main`; the importer uses the locked source. The entrypoint imports the list and writes the text artifact.

## Main challenges

Mana has no CLI revision override. Initialization temporarily selects the historical commit, generates the native lock, and restores the branch declaration. The temporary copy is restored even if initialization fails.

## Alternatives considered

A permanent revision in the manifest would also reproduce the list, but would require editing the declaration to follow main. Automatic entrypoint import would obscure the explicit data import.

## Build and update

With the included pins, build directly:

```sh
nix-build -A systems
cat result
```

The initial file lists `aarch64-darwin`, `aarch64-linux`, `x86_64-darwin`, and
`x86_64-linux`, one per line. It deliberately uses the historical four-system
snapshot recorded in `systems-revision`.

In a disposable copy, follow current main explicitly, then rebuild:

```sh
./update.sh
nix-build -A systems
cat result
```

At validation time, main had removed `x86_64-darwin`. Rebuilding alone keeps the
old list; updating changes the systems lock and leaves nixpkgs fixed.
Maintenance runs the immutable Mana source recorded in `tool-ref`; builds need `fetch-tree`. See the [lab Git configuration notes](../../README.md) if a public HTTPS
lookup is rewritten to SSH.

To reproduce the initial pins in a copy without generated pinning files:

```sh
./init.sh
```

Keep locks, resolvers, and `versions.txt` in version control. `verify-03.sh`
checks the shipped historical snapshot, so it intentionally fails after updates.
