# 01 — GNU Hello with niv

## Goal and approach

Build an existing package from one pinned nixpkgs input.

`nix/sources.json` stores source and update metadata. The generated `nix/sources.nix` fetches the source; `default.nix` imports it and selects Hello.

## Main challenges

Start with `--no-nixpkgs`, then add only nixpkgs with an explicit branch and revision.

## Alternatives considered

niv also supports experimental Git inputs. Its ordinary GitHub archive input is enough for this hash-pinned bootstrap example.

## Build and run

Requires Nix. The niv CLI is only needed to initialize or update pins. The generated pins are included; build directly:

```sh
nix-build
LC_ALL=C ./result/bin/hello
```

Expect `Hello, world!`. Validated on `x86_64-linux` with the same revision and
Hello derivation as the other examples; building leaves inputs unchanged.

## Initialize or update

To reproduce the setup in a directory without generated pins:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#niv --command ./init.sh
```

Keep `nix/sources.json` and generated `nix/sources.nix` and `versions.txt` in version control.
Run updates in a shell containing the same tool, using the pinned `nix shell` reference above.

To explore updates in a disposable copy:

```sh
niv update nixpkgs
```

Review the lock diff. Updating intentionally leaves the common starting revision.
See [lab validation and prerequisites](../../README.md) for tool versions and Git configuration notes.

Reference: [niv documentation](https://github.com/nmattia/niv).
