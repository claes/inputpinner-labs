# 02 — A source archive with Nix flakes

## Goal and approach

Pin the package set and GNU Hello 2.12.3 source separately. Reuse nixpkgs's
Hello recipe, replacing only its `src`; keep the release version unchanged.

Add a tarball input with `flake = false`. Nix unpacks it and locks its tree hash alongside nixpkgs in `flake.lock`. The default package overrides only `src`.

## Main challenges

Without `flake = false`, Nix would try to evaluate a flake inside GNU Hello. The platform list stays explicit, as in 01.

## Alternatives considered

Calling `builtins.fetchTarball` in the output would work, but keep its pin outside the native flake input graph. No adapter library is needed.

## Build and run

Requires Nix with `nix-command` and `flakes` enabled. Locks and resolvers are included, so build directly:

```sh
nix build path:.
LC_ALL=C ./result/bin/hello
LC_ALL=C ./result/bin/hello --version
```

Expect `Hello, world!` and version `2.12.3`.

## Reproduce the pins

In a copy without generated pinning files, run:

```sh
./init.sh
```

Initialization records versions and refuses to reset existing pins. Keep the
locks, generated resolver, and `versions.txt` in version control. The archive
URL is fixed: this example does not discover newer releases. To change releases,
change the URL and align the recipe's version before generating a new pin.

See [the lab index](../../README.md) and `verify-02.sh` for source-content and
build validation. Different source paths can produce different derivations even
when their unpacked contents match.

Reference: [Nix flakes documentation](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-flake.html).
