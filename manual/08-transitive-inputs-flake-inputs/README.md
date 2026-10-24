# 08 — Hello and patchelf share nixpkgs with manual and flake-inputs

Pin nixpkgs once. Use it for our own Hello and pass it to patchelf’s flake,
so its package output builds with the same chosen package set. This combines
the previous sharing exercises 08 and 10 into one comparison.

The main expression makes sharing explicit:

```nix
pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
upstream = (import sources.flake-inputs).import-flake {
  src = sources.patchelf;
  # Use the source that also supplies our own Hello.
  overrides.nixpkgs = sources.nixpkgs;
};
```

The adapter keeps upstream’s existing follows chains and overrides their
shared nixpkgs source at evaluation time. It needs no staging build, rewritten
lock or import-from-derivation. Path overrides omit some flake metadata;
reading the overridden input’s `narHash` is unsupported. Hash the resolved
source path when comparing contents.

Build directly with the included pins; no initializer or pinner CLI is needed:

```sh
nix-build -A hello -o result-hello
nix-build -A patchelf -o result-patchelf
./result-hello/bin/hello
./result-patchelf/bin/patchelf --version
readlink result-hello result-patchelf
```

Expect `Hello, world!` and `patchelf 0.19.2`.

In a disposable copy, change only the parent pin and rebuild:

```sh
./update.sh
nix-build -A hello -o result-hello
nix-build -A patchelf -o result-patchelf
readlink result-hello result-patchelf
```

`alternate-revision` selects the fixed older nixpkgs already recorded in
upstream’s lock. Both output paths change; patchelf’s source and version
stay fixed while its build environment changes. The seed file `revision`
stays unchanged, proving consumption follows the active pin.

Compare the [flake-compat variant](../08-transitive-inputs-flake-compat/README.md):
it stages an adapted lock and needs IFD because its adapter has no override API.

An overlay (07) would use a different upstream interface. Calling outputs
directly would leave the nested input graph to wire manually. `call-flake`
uses a lower-level node interface; `with-inputs` expects supplied dependency
sources and automatic follows. The paired implementations keep this comparison
focused on the two selected libraries.


All examples retain the same nixpkgs and patchelf snapshots. Keep native
declarations, locks, resolvers, revision seeds and versions in Git. To regenerate
the initial pins in another disposable copy, remove `pins.json`, then run:

```sh
./init.sh
```

The manual scripts also need jq and nix-prefetch-url.
`../../verify-08.sh` checks all 14 native/library implementations in
fresh copies with spaces in their paths. Use `--syntax-only` for syntax checks or
`--updates` to test both parent pins.
See the [lab notes](../../README.md) for maintenance and Git configuration.
