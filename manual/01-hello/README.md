# 01 — GNU Hello with Manual baseline

## Goal and approach

Build an existing package from one pinned nixpkgs input.

`pin.json` records a commit URL and hash. `builtins.fetchTarball` verifies the unpacked tree; the entrypoint imports it and selects Hello.

## Main challenges

The compressed archive checksum differs from the unpacked-tree hash. Initialization uses `nix-prefetch-url --unpack` to obtain the hash required by `fetchTarball`.

## Alternatives considered

`builtins.fetchGit` is another baseline. An archive URL and explicit hash make the integrity check visible and parallel the other source fetchers.

## Build and run

Requires Nix. Initialization additionally uses `jq` and `nix-prefetch-url`. The generated pins are included; build directly:

```sh
nix-build
LC_ALL=C ./result/bin/hello
```

Expect `Hello, world!`. Validated on `x86_64-linux` with the same revision and
Hello derivation as the other examples; building leaves inputs unchanged.

## Initialize or update

To reproduce the setup in a directory without generated pins:

```sh
./init.sh
```

Keep `pin.json` and `versions.txt` in version control.

To explore updates in a disposable copy:

Resolve the update branch manually:

```sh
git ls-remote https://github.com/NixOS/nixpkgs.git refs/heads/nixos-26.05
```

Copy the reported commit into `revision`. In a disposable copy, move `pin.json`
aside and rerun `./init.sh` to calculate the new hash.

Review the lock diff. Updating intentionally leaves the common starting revision.
See [lab validation and prerequisites](../../README.md) for tool versions and Git configuration notes.

Reference: [Manual baseline documentation](https://nix.dev/reference/pinning-nixpkgs).
