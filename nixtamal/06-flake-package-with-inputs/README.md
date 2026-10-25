# 06: Consume a flake package with Nixtamal and with-inputs

The parent nixpkgs builds a wrapper that forwards arguments to upstream
patchelf's package output. The single follows declaration preserves upstream's
original nixpkgs independently of the parent.

```sh
nix-build --option allow-import-from-derivation true -A patchelf-demo
./result/bin/patchelf-demo --version
```

Read `default.nix` from top to bottom: `.from.nixtamal` loads the native pins,
`follows` supplies the one input relationship, and `outputs` defines our packages.
The final call is `with-inputs follows outputs`; `system` selects the target.
All teaching code is in this file.

Nixtamal owns four pins: nixpkgs, patchelf, with-inputs, and the separate
upstream-nixpkgs.
Patchelf keeps its package and overlay outputs independent of development
tooling, so flake-parts and git-hooks are not pinned or configured here.

The native loader uses build-time archive records (`fetch-time=build`). Reading
flake files from their outputs requires **IFD (Import From Derivation)**, enabled
explicitly in the commands above. The shipped pins and resolver suffice for
builds without the Nixtamal CLI. `init.sh` recreates them from revision seeds;
remove `nix/tamal/` only in a disposable copy before reinitializing.

Alternatives: evaluation-time fetchers avoid IFD but require wrapping their paths
for the generic with-inputs API. Automatic input matching could share the parent
without an explicit follows in 08; spelling it out illustrates the concept.
Sibling flake-compat, flake-inputs and unflake examples show other evaluators.
