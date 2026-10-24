# 02 — A source archive with niv

## Goal and approach

Pin the package set and GNU Hello 2.12.3 source separately. Reuse nixpkgs's
Hello recipe, replacing only its `src`; keep the release version unchanged.

Two entries in `nix/sources.json` resolve through the generated `nix/sources.nix`. The Hello entry uses a static URL template and `type = "tarball"`; its unpacked directory replaces `src`.

## Main challenges

The release has no GitHub owner or branch to infer. Supply the URL template and tarball type explicitly.

## Alternatives considered

A `file` input could retain the compressed archive and let stdenv unpack it. Tarball input keeps the source-directory comparison consistent.

## Build and run

Requires Nix; niv is only needed to initialize or maintain the pins. Locks and resolvers are included, so build directly:

```sh
nix-build
LC_ALL=C ./result/bin/hello
LC_ALL=C ./result/bin/hello --version
```

Expect `Hello, world!` and version `2.12.3`.

## Reproduce the pins

In a copy without generated pinning files, run:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#niv --command ./init.sh
```

Initialization records versions and refuses to reset existing pins. Keep the
locks, generated resolver, and `versions.txt` in version control. The archive
URL is fixed: this example does not discover newer releases. To change releases,
change the URL and align the recipe's version before generating a new pin.

See [the lab index](../../README.md) and `verify-02.sh` for source-content and
build validation. Different source paths can produce different derivations even
when their unpacked contents match.

Reference: [niv documentation](https://github.com/nmattia/niv).
