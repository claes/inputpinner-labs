# 01 — GNU Hello with Lon

## Goal and approach

Build an existing package from one pinned nixpkgs input.

Lon maintains `lon.lock` and generates `lon.nix`. The resolver exposes the source, which `default.nix` imports to select Hello.

## Main challenges

The positional branch selects future updates; `--revision` independently selects the starting commit.

## Alternatives considered

Lon supports generic Git and lockable HTTP tarballs. Its GitHub archive input is sufficient here; no update bot or overrides are needed.

## Build and run

Requires Nix. The Lon CLI is only needed to initialize or update pins. The generated pins are included; build directly:

```sh
nix-build
LC_ALL=C ./result/bin/hello
```

Expect `Hello, world!`. Validated on `x86_64-linux` with the same revision and
Hello derivation as the other examples; building leaves inputs unchanged.

## Initialize or update

To reproduce the setup in a directory without generated pins:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#lon --command ./init.sh
```

Keep `lon.lock` and generated `lon.nix` and `versions.txt` in version control.
Run updates in a shell containing the same tool, using the pinned `nix shell` reference above.

To explore updates in a disposable copy:

```sh
lon update nixpkgs
```

Review the lock diff. Updating intentionally leaves the common starting revision.
See [lab validation and prerequisites](../../README.md) for tool versions and Git configuration notes.

Reference: [Lon documentation](https://github.com/nikstur/lon).
