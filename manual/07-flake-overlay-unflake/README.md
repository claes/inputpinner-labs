# 07 — Flake overlay with manual and unflake

Apply upstream’s `overlays.default` to our parent nixpkgs and build
`patchelf-new`. The existing `patchelf` attribute stays at 0.15.2.
The upstream input graph still has its separate nixpkgs pin.

```nix
# The pinner fetches sources; the generated code supplies flake inputs/outputs.
upstream = (import ./unflake.nix).patchelf;
```

manual owns every source pin and fetch. `sources.nix` loads its native resolver;
`unflake-sources.nix` maps those records to the source shape expected by
unflake’s npins backend. This small bridge is lab-maintained, not an upstream
manual backend. Initialization replaces exactly one generated import, checking
that it appears once, and leaves unflake’s evaluation logic intact.

Build using the included locks and generated files. No maintenance CLI or
initialization is needed, and evaluation needs no import-from-derivation:

```sh
nix-build
./result/bin/patchelf --version
```

Expect `patchelf 0.19.2`.

Unlike flake-compat and flake-inputs, unflake **ignores upstream lockfiles**.
`inputs.nix` explicitly selects fixed transitive revisions, so regeneration
cannot silently choose today’s development dependencies. Its deduplication
rules recognize GitHub refs, flake-parts’ nixpkgs tarball and gitignore’s
registry-style `nixpkgs` input; consumption never consults your registry.

This unflake revision also ignores nested input overrides. Consequently we
retain explicit gitignore and flake-compat source pins for git-hooks’ graph,
even though these are not needed to evaluate the package. That flake-compat
source is an incidental upstream development dependency: **unflake evaluates
the flakes in this variant**.

The rules merge transitive nixpkgs references into `upstream-nixpkgs`,
matching the existing examples’ upstream nixpkgs revision while keeping our
parent separate. This is explicit pinning, not preservation of the upstream
lockfile’s full graph. Example 08 instead merges these sources with the parent.

Alternatives considered: the [flake-compat variant](../07-flake-overlay-flake-compat/README.md)
and [flake-inputs variant](../07-flake-overlay-flake-inputs/README.md) consume upstream
locks directly. Unflake’s built-in Nix backend would also work, but would own
fetching separately from manual; that would weaken this pinner comparison.
Using npins for the whole example would avoid the custom bridge. Here npins
is only a maintenance-time generator backend, run in a temporary directory;
it is not a second source resolver during builds.

To regenerate from scratch, use a disposable copy, remove `pins.json`,
and run the initializer in a shell containing the maintenance tools:

```sh
nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/2efa67fd26b6df417c33e4603185c701f260dd83.tar.gz \
  -p npins --run ./init.sh
```

Nix and jq are also required. `unflake-tool-ref` pins unflake to
`22d908471bf3201856cd10d22813d85c66a75907`; the initializer runs that source
through `nix run -f`. `versions.txt` records the actual tools used.

`../../verify-07.sh` checks the existing variants and these six unflake
variants in fresh copies with spaces in their paths. Use `--syntax-only`
for parsing checks.
See the [lab notes](../../README.md) and [unflake documentation](https://codeberg.org/goldstein/unflake)
for the source/backend distinction and maintenance prerequisites.
