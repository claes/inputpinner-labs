# 02 — A source archive with npins

## Goal and approach

Pin the package set and GNU Hello 2.12.3 source separately. Reuse nixpkgs's
Hello recipe, replacing only its `src`; keep the release version unchanged.

Keep the nixpkgs GitHub pin and add a named `hello` tarball pin. The generated resolver exposes both inputs, and the package expression replaces only `src`.

## Main challenges

The archive input records a fixed URL and unpacked-tree hash. It does not infer a newer GNU release.

## Alternatives considered

`pkgs.fetchurl` could fetch the archive inside the package expression, but would leave its pin outside npins. Native tarball input makes the two managed sources visible together.

## Build and run

Requires Nix; npins is only needed to initialize or maintain the pins. Locks and resolvers are included, so build directly:

```sh
nix-build
LC_ALL=C ./result/bin/hello
LC_ALL=C ./result/bin/hello --version
```

Expect `Hello, world!` and version `2.12.3`.

## Reproduce the pins

In a copy without generated pinning files, run:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#npins --command ./init.sh
```

Initialization records versions and refuses to reset existing pins. Keep the
locks, generated resolver, and `versions.txt` in version control. The archive
URL is fixed: this example does not discover newer releases. To change releases,
change the URL and align the recipe's version before generating a new pin.

See [the lab index](../../README.md) and `verify-02.sh` for source-content and
build validation. Different source paths can produce different derivations even
when their unpacked contents match.

Reference: [npins documentation](https://github.com/andir/npins).
