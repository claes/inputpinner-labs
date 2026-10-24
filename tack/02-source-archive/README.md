# 02 — A source archive with tack

## Goal and approach

Pin the package set and GNU Hello 2.12.3 source separately. Reuse nixpkgs's
Hello recipe, replacing only its `src`; keep the release version unchanged.

The nixpkgs input remains source-only. Hello uses `--fixed --unpack tarball`: tack locks the compressed download hash, then the resolver downloads and unpacks it before the package build.

## Main challenges

Most other examples lock an unpacked-tree hash. tack's fixed input instead verifies archive bytes. Compare the materialized source directories to establish equivalent contents.

## Alternatives considered

`--fetch` could use source-tree fetching. Fixed mode better expresses an immutable release download and refuses silently accepting changed content.

## Build and run

Requires Nix with `fetch-tree` enabled; tack is only needed to initialize or maintain the pins. Locks and resolvers are included, so build directly:

```sh
nix-build
LC_ALL=C ./result/bin/hello
LC_ALL=C ./result/bin/hello --version
```

Expect `Hello, world!` and version `2.12.3`.

## Reproduce the pins

In a copy without generated pinning files, run:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#tack --command ./init.sh
```

Initialization records versions and refuses to reset existing pins. Keep the
locks, generated resolver, and `versions.txt` in version control. The archive
URL is fixed: this example does not discover newer releases. To change releases,
change the URL and align the recipe's version before generating a new pin.

See [the lab index](../../README.md) and `verify-02.sh` for source-content and
build validation. Different source paths can produce different derivations even
when their unpacked contents match.

Reference: [tack documentation](https://github.com/manic-systems/tack).
