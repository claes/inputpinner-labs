# 01 — GNU Hello with Nix flakes

## Goal and approach

Build an existing package from one pinned nixpkgs input.

The manifest names the update branch; `flake.lock` records its exact commit and tree hash. The output imports that source and selects `pkgs.hello`.

## Main challenges

List the platforms explicitly because flake evaluation has no implicit host system. Use `path:.` so exported directories work too.

## Alternatives considered

`flake-utils` could generate platform attributes. A visible list and `map` avoid another input and keep the steps readable.

## Build and run

Requires Nix with `nix-command` and `flakes` enabled. The generated pins are included; build directly:

```sh
nix build path:.
LC_ALL=C ./result/bin/hello
```

Expect `Hello, world!`. Validated on `x86_64-linux` with the same revision and
Hello derivation as the other examples; building leaves inputs unchanged.

## Initialize or update

To reproduce the setup in a directory without generated pins:

```sh
./init.sh
```

Keep `flake.lock` and `versions.txt` in version control.

To explore updates in a disposable copy:

```sh
nix flake update --flake path:. nixpkgs
```

Review the lock diff. Updating intentionally leaves the common starting revision.
See [lab validation and prerequisites](../../README.md) for tool versions and Git configuration notes.

Reference: [Nix flakes documentation](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-flake.html).
