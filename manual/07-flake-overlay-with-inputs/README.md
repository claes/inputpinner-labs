# 07: Apply a flake overlay with manual and with-inputs

Apply upstream's overlay to the parent package set. Build its added
`patchelf-new` attribute while preserving the original `pkgs.patchelf`.

```sh
nix-build -A patchelf-new
./result/bin/patchelf --version
```

Read `default.nix` from top to bottom: `sources` provides the pinned trees,
`with-inputs` binds those sources, `follows` declares their relationships, and
`outputs` defines our packages from resolved inputs. Everything is in this file.
The final call supplies `[ follows inputsOverrides ]` and `outputs`, completing
[with-inputs' sources → follows → outputs interface](https://github.com/denful/with-inputs/tree/641d01ef95eae1aeaa257ffd48102ab9a308f2a2#api). Caller overrides take
precedence; `system` selects the target system. The result exposes named package
outputs, `.inputs`, `.outputs` and `inputs.self`.

The manual fetch expression wraps each unpacked archive as an `outPath` source
record. The generic API binds these sources and supplies project `self`.

Explicit follows keep patchelf and its transitive nixpkgs inputs on the separate
`upstream-nixpkgs` pin. Our output function uses parent `inputs.nixpkgs`.
The `nixpkgs-lib` and `nixpkgs-stable` aliases use the intended nixpkgs too.
Empty follows disconnect upstream's optional gitignore and flake-compat inputs.
This graph supports package and overlay consumption; it does not reproduce
upstream development checks.

The shipped pins, resolver and version record suffice for builds without a
maintenance CLI. `init.sh` recreates the pins from revision seeds in a fresh
copy and refuses to overwrite existing records. Before reinitializing a
**disposable** copy, remove `pins.json`.

Alternatives: upstream separates the bindings into files; this lab keeps them
together so the whole example is visible. Automatic name matching could replace
the explicit patchelf follows in 08, but would hide the teaching point. The
library's `from.flake` helper could fetch lock-file sources; native pins keep
fetching under the pinner being compared. Sibling flake-compat, flake-inputs and
unflake variants show other evaluators.
