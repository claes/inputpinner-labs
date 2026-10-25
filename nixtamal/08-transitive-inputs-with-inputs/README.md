# 08: Share the parent nixpkgs with Nixtamal and with-inputs

Build parent `hello` and upstream `patchelf` with the same nixpkgs. The single
`patchelf.inputs.nixpkgs.follows = "nixpkgs"` makes that sharing explicit. In a
disposable copy, `./update.sh` selects the fixed alternate parent pin: both
package derivations change, while patchelf and with-inputs stay pinned.

```sh
nix-build --option allow-import-from-derivation true -A hello -o result-hello
nix-build --option allow-import-from-derivation true -A patchelf -o result-patchelf
./result-hello/bin/hello
./result-patchelf/bin/patchelf --version
```

Read `default.nix` from top to bottom: `.from.nixtamal` loads the native pins,
`follows` supplies the one input relationship, and `outputs` defines our packages.
The final call is `with-inputs follows outputs`; `system` selects the target.
All teaching code is in this file.

Nixtamal owns three pins: nixpkgs, patchelf, with-inputs.
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
