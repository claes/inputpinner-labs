# 01 — GNU Hello with tack

## Goal and approach

Build an existing package from one pinned nixpkgs input.

`.tack/pins.toml` declares the source; the lock and generated resolver supply its exact tree. The entrypoint imports it and selects Hello.

## Main challenges

`--fetch` requests the source tree, keeping flake output evaluation out of this example. The initial URL contains the common commit.

## Alternatives considered

tack can evaluate upstream flakes natively. That is reserved for example 06; source-only consumption keeps this comparison focused on pinning nixpkgs.

## Build and run

Requires Nix with `fetch-tree` enabled. tack is only needed to initialize or update pins. The generated pins are included; build directly:

```sh
nix-build
LC_ALL=C ./result/bin/hello
```

Expect `Hello, world!`. Validated on `x86_64-linux` with the same revision and
Hello derivation as the other examples; building leaves inputs unchanged.

## Initialize or update

To reproduce the setup in a directory without generated pins:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#tack --command ./init.sh
```

Keep `.tack/pins.toml`, `pins.lock.json`, and generated `default.nix` and `versions.txt` in version control.
Run updates in a shell containing the same tool, using the pinned `nix shell` reference above.

To explore updates in a disposable copy:

First change the nixpkgs URL in `.tack/pins.toml` to `github:NixOS/nixpkgs/nixos-26.05`.

```sh
tack update nixpkgs
```

Review the lock diff. Updating intentionally leaves the common starting revision.
See [lab validation and prerequisites](../../README.md) for tool versions and Git configuration notes.

Reference: [tack documentation](https://github.com/manic-systems/tack).
