# 09 — Patch a pinned source with tack

Reuse 03’s small `nix-systems/default` dependency. `local.patch` replaces
`x86_64-darwin` with `riscv64-linux` in its Nix list. The output is a single
patched Nix file, showing how local changes compose with an immutable source pin.

The generated resolver supplies the raw `systems` source from `.tack/pins.lock.json`. The updater changes the manifest URL to the second immutable commit and runs `tack update systems`; nixpkgs stays pinned.

The fetch hash checks the original source before patching. Nixpkgs unpacks it,
applies `patches`, then installs `default.nix` as `$out`. The patch itself is a
derivation input; it does not change the upstream pin or its hash. Strict patch
flags reject fuzzy matches, reversed patches and interactive prompts. There is
no compiler and no import-from-derivation: evaluate the output only after building.

Build directly with the included locks and resolvers; no pinner CLI or
initialization is needed:

```sh
nix-build
cat result
nix eval --json --file ./result
```

The result contains `aarch64-darwin`, `aarch64-linux`, `riscv64-linux`, and
`x86_64-linux`, in that order. The artifact retains Nix list syntax.

In a **disposable copy**, run the complete update exercise:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#tack --command ./update.sh
nix-build  # Expected failure: the old patch no longer applies.
# Review upstream default.nix and the supplied repair before adopting it.
diff -u local.patch local.after-update.patch  # Exit 1 means differences were found.
cp local.after-update.patch local.patch
nix-build
cat result
```

The initial revision is `da67096a3b9bf56a91d16901293e51ba5b49a27e`.
`updated-systems-revision` selects `d36eeed142f88b5a636f2e3856a53c61654cf29b`,
which already removed `x86_64-darwin`. Source locking succeeds, but the old
replacement hunk fails during the build. The reviewed repair instead adds
`riscv64-linux`, restoring the same final list. `update.sh` never repairs or
drops patches; nixpkgs stays unchanged. A fixed update target keeps this exercise
repeatable as main advances. These seeds are fixtures, not claims about current main.

An `applyPatches` helper followed by importing the derived Nix file would
introduce import-from-derivation. Plain text substitution would obscure the
context-sensitive failure demonstrated here. Neither extra library nor source
fork is needed for this small build-time patch.

To regenerate the starting pins, make another disposable copy and remove
`.tack/`. Run `nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#tack --command ./init.sh`. See [03](../03-git-branch/README.md) for the same
maintenance tool setup and [the lab notes](../../README.md) for Git configuration.
Keep the native declarations, locks, resolvers, patches and recorded tool versions
in version control. From the lab root, `./verify-09.sh` checks the shipped state;
`./verify-09.sh --updates` also tests the deliberate failure and repair in copies.
