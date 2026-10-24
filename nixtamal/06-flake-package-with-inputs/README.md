# 06: Use a flake package with nixtamal and with-inputs

Build a parent-owned wrapper around upstream patchelf's package output.

```sh
nix-build --option allow-import-from-derivation true -A patchelf-demo
./result/bin/patchelf-demo --version
```

Read `default.nix` from top to bottom: `with-inputs` loads the native pins,
`follows` declares their relationships, and `outputs` defines our packages from
resolved inputs. The final call supplies `[ follows inputsOverrides ]` and
`outputs`, completing the library's sources → follows → outputs interface.
Caller overrides take precedence; `system` selects the target system. The result
exposes named packages, `.inputs`, `.outputs` and `inputs.self`.

The `.from.nixtamal` loader supplies source handling and project `self` metadata:

```nix
with-inputs =
  (import (import ./nix/tamal {}).with-inputs).from.nixtamal ./.;
```

The manifest uses `fetch-time=build`: native archive fetchers return source
records accepted by this loader. Reading `flake.nix` from their build outputs
requires **IFD (Import From Derivation)**. Evaluation may therefore build the
source fetchers before defining our packages; the commands above explicitly
allow this. No source conversion or manual `self` setup is needed.

Explicit follows keep patchelf and its transitive nixpkgs inputs on the separate
`upstream-nixpkgs` pin. Our output function uses parent `inputs.nixpkgs`.
The `nixpkgs-lib` and `nixpkgs-stable` aliases use the intended nixpkgs too.
Empty follows disconnect upstream's optional gitignore and flake-compat inputs.
This graph supports package and overlay consumption; it does not reproduce
upstream development checks.

The shipped pins, resolver and version record suffice for builds without a
maintenance CLI. `init.sh` recreates the pins from revision seeds in a fresh
copy and refuses to overwrite existing records. Before reinitializing a
**disposable** copy, remove `nix/tamal/`.

Alternatives: `fetch-time=eval` would avoid IFD, but its bare paths need a
conversion before the generic with-inputs API can use them. The native loader
is chosen here for clarity. Upstream separates the bindings into files; this lab keeps them
together so the whole example is visible. Automatic name matching could replace
the explicit patchelf follows in 08, but would hide the teaching point. The
library's `from.flake` helper could fetch lock-file sources; native pins keep
fetching under the pinner being compared. Sibling flake-compat, flake-inputs and
unflake variants show other evaluators.
