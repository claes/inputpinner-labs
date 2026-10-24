# 08 — Hello and patchelf share nixpkgs with mana and flake-compat

Pin nixpkgs once. Use it for our own Hello and pass it to patchelf’s flake,
so its package output builds with the same chosen package set. This combines
the previous sharing exercises 08 and 10 into one comparison.

The pinned flake-compat interface has no input override argument. The
commented `share-nixpkgs.nix` helper stages a copy of upstream with its
nixpkgs lock node replaced using the parent’s **active** revision and the
hash of its resolved source. Existing follows chains reach that replacement.
The original source and project lock stay unchanged.

Importing the staged tree needs `allow-import-from-derivation = true`.
The helper targets this fixture’s GitHub nixpkgs pin and version-7 lock. It
may fetch the same parent tree under a different native name; contents and
revision remain identical. The adapter itself does not implement sharing.

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

Compare the [flake-inputs variant](../08-transitive-inputs-flake-inputs/README.md):
it uses a direct source override and avoids the staging build and IFD.

An overlay (07) would use a different upstream interface. Calling outputs
directly would leave the nested input graph to wire manually. `call-flake`
uses a lower-level node interface; `with-inputs` expects supplied dependency
sources and automatic follows. The paired implementations keep this comparison
focused on the two selected libraries.


All examples retain the same nixpkgs and patchelf snapshots. Keep native
declarations, locks, resolvers, revision seeds and versions in Git. To regenerate
the initial pins in another disposable copy, remove `lock.json` and `nix/`, then run:

```sh
./init.sh
```

Mana maintenance requires a path without spaces due to its pinned CLI’s
cwd quoting bug. Consuming its saved locks works in paths containing spaces.
`../../verify-08.sh` checks all 14 native/library implementations in
fresh copies with spaces in their paths. Use `--syntax-only` for syntax checks or
`--updates` to test both parent pins.
See the [lab notes](../../README.md) for maintenance and Git configuration.
