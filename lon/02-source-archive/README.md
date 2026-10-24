# 02 — A source archive with Lon

## Goal and approach

Pin the package set and GNU Hello 2.12.3 source separately. Reuse nixpkgs's
Hello recipe, replacing only its `src`; keep the release version unchanged.

A GitHub pin supplies nixpkgs, and a native tarball pin supplies Hello. `lon.nix` resolves both; the existing recipe is reused with the tarball source.

## Main challenges

Lon 0.8.0 from example 01 has no tarball command. This example pins Lon 1.0.0 at the immutable source in `tool-ref`; initialization may build that tool.

## Alternatives considered

An extra manual `fetchTarball` would avoid upgrading Lon, but would put Hello outside its lock. The newer native command illustrates archive pinning directly.

## Build and run

Requires Nix; initialization additionally needs `nix-command` and `flakes` to run the pinned Lon tool. Locks and resolvers are included, so build directly:

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

Reference: [Lon documentation](https://github.com/nikstur/lon).
