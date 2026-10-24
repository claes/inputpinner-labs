# 01 — GNU Hello with npins

## Goal and approach

Build an existing package from one pinned nixpkgs input.

The CLI maintains `npins/sources.json`; its generated resolver exposes nixpkgs as a source. The handwritten entrypoint imports the source and selects Hello.

## Main challenges

`--bare` avoids an extra default channel. `--at` selects the starting commit while `--branch` retains the update target.

## Alternatives considered

npins can track Nix channels. A GitHub branch pin makes the exact source commit directly comparable with the other examples.

## Build and run

Requires Nix. The npins CLI is only needed to initialize or update pins. The generated pins are included; build directly:

```sh
nix-build
LC_ALL=C ./result/bin/hello
```

Expect `Hello, world!`. Validated on `x86_64-linux` with the same revision and
Hello derivation as the other examples; building leaves inputs unchanged.

## Initialize or update

To reproduce the setup in a directory without generated pins:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#npins --command ./init.sh
```

Keep `npins/sources.json` and generated `npins/default.nix` and `versions.txt` in version control.
Run updates in a shell containing the same tool, using the pinned `nix shell` reference above.

To explore updates in a disposable copy:

```sh
npins update nixpkgs
```

Review the lock diff. Updating intentionally leaves the common starting revision.
See [lab validation and prerequisites](../../README.md) for tool versions and Git configuration notes.

Reference: [npins documentation](https://github.com/andir/npins).
