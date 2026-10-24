# 01 — GNU Hello with Mana

## Goal and approach

Build an existing package from one pinned nixpkgs input.

`mana.nix` requests nixpkgs as a raw source. The generated importer injects it into `entrypoint.nix`, which imports the package set and exposes `hello`.

## Main challenges

`entrypoint = null` prevents automatic dependency imports. `mana upgrade` generates only the importer, preserving the small handwritten example.

## Alternatives considered

`mana init` also scaffolds a manifest and entrypoint. It was unnecessary here. Automatic dependency imports would obscure the explicit nixpkgs import.

## Build and run

Requires Nix with `nix-command`, `flakes`, and `fetch-tree` enabled. The generated pins are included; build directly:

```sh
nix-build -A hello
LC_ALL=C ./result/bin/hello
```

Expect `Hello, world!`. Validated on `x86_64-linux` with the same revision and
Hello derivation as the other examples; building leaves inputs unchanged.

## Initialize or update

To reproduce the setup in a directory without generated pins:

```sh
./init.sh
```

Keep `mana.nix`, `lock.json`, generated `nix/importer.nix`, and `tool-ref` and `versions.txt` in version control.
Mana has no version flag; `tool-ref` records its immutable source revision.

To explore updates in a disposable copy:

First change the dependency URL in `mana.nix` to `github:NixOS/nixpkgs/nixos-26.05`.

```sh
nix run "$(cat tool-ref)" -- update nixpkgs
```

Review the lock diff. Updating intentionally leaves the common starting revision.
See [lab validation and prerequisites](../../README.md) for tool versions and Git configuration notes.

Reference: [Mana documentation](https://github.com/hsjobeki/mana).
