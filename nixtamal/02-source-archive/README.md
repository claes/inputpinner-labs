# 02 — A source archive with Nixtamal

## Goal and approach

Pin the package set and GNU Hello 2.12.3 source separately. Reuse nixpkgs's
Hello recipe, replacing only its `src`; keep the release version unchanged.

The KDL manifest declares two archives: nixpkgs uses the initial revision as its freshness value; Hello uses a fixed release URL. The generated resolver supplies both sources.

## Main challenges

Evaluation-time fetching yields unpacked source directories. The release URL needs no custom freshness command; the literal nixpkgs freshness value preserves comparability with 01.

## Alternatives considered

Build-time archive fetching through nixpkgs is also available. Built-in fetching keeps this example focused on two independently locked source trees.

## Build and run

Requires Nix; Nixtamal is only needed to initialize or maintain the pins. Locks and resolvers are included, so build directly:

```sh
nix-build
LC_ALL=C ./result/bin/hello
LC_ALL=C ./result/bin/hello --version
```

Expect `Hello, world!` and version `2.12.3`.

## Reproduce the pins

In a copy without generated pinning files, run:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#nixtamal.bin --command ./init.sh
```

Initialization records versions and refuses to reset existing pins. Keep the
locks, generated resolver, and `versions.txt` in version control. The archive
URL is fixed: this example does not discover newer releases. To change releases,
change the URL and align the recipe's version before generating a new pin.

See [the lab index](../../README.md) and `verify-02.sh` for source-content and
build validation. Different source paths can produce different derivations even
when their unpacked contents match.

Reference: [Nixtamal documentation](https://nixtamal.toast.al/manpage/nixtamal-manifest.5/).
