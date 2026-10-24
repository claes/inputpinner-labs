# 08 — Transitive inputs with mana and unflake

Build `hello` from our parent nixpkgs and `patchelf` from the upstream
flake output. Both use the **same nixpkgs source**, including the nixpkgs
inputs of flake-parts, git-hooks and gitignore.

```nix
# The pinner fetches sources; the generated code supplies flake inputs/outputs.
upstream = (import ./unflake.nix).patchelf;
```

mana owns every source pin and fetch. `sources.nix` loads its native resolver;
`unflake-sources.nix` maps those records to the source shape expected by
unflake’s npins backend. This small bridge is lab-maintained, not an upstream
mana backend. Initialization replaces exactly one generated import, checking
that it appears once, and leaves unflake’s evaluation logic intact.

These tarball-backed sources expose the path and active revision to unflake,
following its npins backend. They do not supply all `fetchTree` metadata such
as `narHash` or `lastModified`; these outputs do not require it.

Build using the included locks and generated files. No maintenance CLI or
initialization is needed, and evaluation needs no import-from-derivation:

```sh
nix-build -A hello -o result-hello
nix-build -A patchelf -o result-patchelf
./result-hello/bin/hello
./result-patchelf/bin/patchelf --version
```

Expect `patchelf 0.19.2` and `Hello, world!`.

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

The rules merge the transitive nixpkgs references with the parent input.
Run `./update.sh` in a disposable copy to move only that native pin to
`alternate-revision`. Hello and patchelf both acquire new derivations; the
patchelf version/source and other pins stay fixed. No evaluator regeneration
is needed. Generated IDs contain their initial revision as a label; the active
native lock supplies the current source and revision after an update.

Alternatives considered: the [flake-compat variant](../08-transitive-inputs-flake-compat/README.md)
and [flake-inputs variant](../08-transitive-inputs-flake-inputs/README.md) consume upstream
locks directly. Unflake’s built-in Nix backend would also work, but would own
fetching separately from mana; that would weaken this pinner comparison.
Using npins for the whole example would avoid the custom bridge. Here npins
is only a maintenance-time generator backend, run in a temporary directory;
it is not a second source resolver during builds.
Calling unflake’s internal generator could avoid that temporary stage, but
would require a custom backend tied to its Python internals.

To regenerate from scratch, use a disposable copy, remove `lock.json`,
and run the initializer in a shell containing the maintenance tools:

```sh
nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/2efa67fd26b6df417c33e4603185c701f260dd83.tar.gz \
  -p npins --run ./init.sh
```

Nix and jq are also required. `unflake-tool-ref` pins unflake to
`22d908471bf3201856cd10d22813d85c66a75907`; the initializer runs that source
through `nix run -f`. `versions.txt` records the actual tools used.
Mana’s separate `tool-ref` pins its maintenance CLI. `raw-sources.nix`
returns its injected dependencies for the source bridge. Run Mana maintenance
outside paths containing spaces; normal consumption supports those paths.

`../../verify-08.sh` checks the existing variants and these six unflake
variants in fresh copies with spaces in their paths. Use `--syntax-only`
for parsing checks or `--updates` to exercise parent-only updates.
See the [lab notes](../../README.md) and [unflake documentation](https://codeberg.org/goldstein/unflake)
for the source/backend distinction and maintenance prerequisites.
