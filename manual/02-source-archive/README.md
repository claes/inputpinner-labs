# 02 — A source archive with Manual baseline

## Goal and approach

Pin the package set and GNU Hello 2.12.3 source separately. Reuse nixpkgs's
Hello recipe, replacing only its `src`; keep the release version unchanged.

`pins.json` contains separate nixpkgs and Hello records. Two explicit `builtins.fetchTarball` calls resolve them, and the existing package recipe is overridden with `sources.hello`.

## Main challenges

Use `nix-prefetch-url --unpack` for each input: these hashes describe source trees rather than compressed files. The pins remain independent of the build recipe.

## Alternatives considered

`pkgs.fetchurl` could verify archive bytes and leave unpacking to stdenv. This baseline uses explicit unpacked-tree pins to match the source model of most pinners.

## Build and run

Requires Nix; initialization additionally requires `jq` and `nix-prefetch-url`. Locks and resolvers are included, so build directly:

```sh
nix-build
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

Reference: [Manual baseline documentation](https://nix.dev/reference/pinning-nixpkgs).
