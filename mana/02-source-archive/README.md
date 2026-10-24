# 02 — A source archive with Mana

## Goal and approach

Pin the package set and GNU Hello 2.12.3 source separately. Reuse nixpkgs's
Hello recipe, replacing only its `src`; keep the release version unchanged.

Declare nixpkgs and Hello in `mana.nix` with `entrypoint = null`. The importer injects raw source trees into `entrypoint.nix`; the Hello source replaces `src` in the package recipe.

## Main challenges

Both dependencies are data for this entrypoint, so disable automatic Nix entrypoint imports. `tool-ref` pins the Mana implementation used to generate the importer.

## Alternatives considered

Automatic dependency imports help with Nix libraries, but this release archive contains application sources. A raw dependency makes that distinction explicit.

## Build and run

Requires Nix with `fetch-tree` enabled; initialization also uses `nix-command` and `flakes`. Locks and resolvers are included, so build directly:

```sh
nix-build -A hello
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

Reference: [Mana documentation](https://github.com/hsjobeki/mana).
