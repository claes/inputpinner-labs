# Nix input pinner lab

Small, commented examples comparing input pinning approaches. Matching numbers
mean the same task across tools. Read the Nix expression beside each example's
short README: the goal is to make the steps understandable, not to minimize lines.

## Working on the lab

Run `./start-codex.sh` from your normal terminal to start Codex in this project
with workspace sandboxing, network access, and user approval requests enabled.
If access to the Nix daemon socket is blocked, Codex can request approval for
the affected command outside the sandbox. Additional Codex arguments are
forwarded, for example `./start-codex.sh resume`. App or administrator policies
can still restrict these settings; the launcher does not change an existing
managed session. See the [Codex configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference).

Run `./clean.sh` to remove `result`/`result-*` symlinks, abandoned `*.tmp`
files, and Mana's staged `next_lock.json` inside numbered examples.
It works from any directory and does not follow
symlinks. Locks, resolvers, version records, source files, and Nix store contents
are retained. `.gitignore` excludes these disposable example artifacts.

## Example 01: GNU Hello

| Approach | Example | How inputs are consumed |
| --- | --- | --- |
| Nix flakes | [01-hello](flake/01-hello) | Native locked flake input |
| niv | [01-hello](niv/01-hello) | Generated `nix/sources.nix` |
| npins | [01-hello](npins/01-hello) | Generated `npins/default.nix` |
| Nixtamal | [01-hello](nixtamal/01-hello) | Generated `nix/tamal` resolver |
| tack | [01-hello](tack/01-hello) | Source-only input through `.tack` |
| Lon | [01-hello](lon/01-hello) | Generated `lon.nix` |
| Mana | [01-hello](mana/01-hello) | Generated importer injects the source |
| Manual | [01-hello](manual/01-hello) | Explicit URL and unpacked hash |

Every example has its own copy of `revision`, initially
`2efa67fd26b6df417c33e4603185c701f260dd83`, taken from the host's
NixOS 26.05 installation (`nixos-version --json`). It is an immutable starting
point; `nixos-26.05` is the intended update branch. No example reads a sibling's
files or depends on channels or `<nixpkgs>` when building.

### Validation and prerequisites

All eight examples build and print `Hello, world!` on `x86_64-linux` using
Nix 2.34.8. They resolve the same nixpkgs commit and the same GNU Hello 2.12.3
derivation. Generated locks and resolvers are included, so building does not
require the pinner CLIs or rerunning initialization. Other platforms are untested.
The comparison also passes from a fresh copy in a path containing spaces,
without running initialization.

Run `./verify-01.sh` to check the locked revisions, build and run each example,
compare derivation paths, and confirm that building leaves files unchanged.
It requires Nix, `jq`, and the usual GNU command-line utilities. Run
`./verify-01.sh --syntax-only` for Nix and Bash parsing checks without building.
The comparison intentionally fails after an example is updated away from the
common starting revision.

| Tool | Recorded version/source |
| --- | --- |
| niv | 0.2.22 |
| npins | 0.4.2 |
| Lon | 0.8.0 |
| Nixtamal | 1.5.4 |
| tack | CLI reports 0.1.1; nixpkgs package is 1.0.0 |
| Mana | `hsjobeki/mana` at `d28a1a1ac83aec04dff4d2f92d3b580cfbaa1df4` |

`versions.txt` records the actual Nix/tool versions. Mana has no version flag;
its `tool-ref` pins the source used to generate the importer. The other tools
come from the same pinned nixpkgs as the examples; each README gives an explicit
`nix shell` bootstrap command. No tool installation or development shell is
needed for normal consumption.

Update workflows are exercised in disposable copies so the checked-in comparison
retains its initial pins. All eight documented workflows advanced to
`da6dc0e7b26060f2f71ce3ef7088fb56ee44fa36` during validation.
Nixtamal 1.5.4's setup revision flag did not retain the
requested commit; its example uses an explicit freshness value instead. tack and
Mana start with commit-specific URLs. Their READMEs explain switching to the
`nixos-26.05` branch before updating.

Some host Git configurations rewrite GitHub HTTPS URLs to SSH. Nixtamal's branch
freshness command and the manual branch lookup then need working SSH credentials
or a neutral Git configuration. For a public HTTPS lookup, run the affected
command with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` in its environment.
This is a host configuration issue; the examples do not change global Git settings.

## Example 02: A separately pinned source archive

Each example keeps the nixpkgs revision from 01 and adds the fixed release URL
`https://ftp.gnu.org/gnu/hello/hello-2.12.3.tar.gz` as a second input. It reuses
nixpkgs's Hello recipe with only `src` overridden. The archive version matches
the recipe, so no packaging or version changes distract from input pinning.

| Approach | Example | Archive handling |
| --- | --- | --- |
| Nix flakes | [02-source-archive](flake/02-source-archive) | Non-flake tarball input |
| niv | [02-source-archive](niv/02-source-archive) | Static URL template with tarball type |
| npins | [02-source-archive](npins/02-source-archive) | Named tarball input |
| Nixtamal | [02-source-archive](nixtamal/02-source-archive) | Evaluation-time archive input |
| tack | [02-source-archive](tack/02-source-archive) | Fixed download followed by unpacking |
| Lon | [02-source-archive](lon/02-source-archive) | Native tarball input in pinned Lon 1.0.0 |
| Mana | [02-source-archive](mana/02-source-archive) | Raw tarball dependency injection |
| Manual | [02-source-archive](manual/02-source-archive) | Two explicit URL/tree-hash records |

The generated locks and resolvers are included. Build directly with each README's
commands; initialization is only needed to reproduce the pins. Example 02 uses
the same tool versions as 01 except Lon: 0.8.0 lacks tarball input support, so its
`tool-ref` pins 1.0.0 at `84dd64dca90c155ac08e559c116b9baf6ca31657`.
Running that initializer may compile Lon; normal consumption does not need it.

`./verify-02.sh` checks both locked inputs, confirms the package uses the resolved
Hello source, compares unpacked source hashes, builds and checks the greeting and
version, and checks files remain unchanged. It requires the same utilities as
`verify-01.sh`. `./verify-02.sh --syntax-only` parses example 02 without building.
All eight pass on `x86_64-linux` with Nix 2.34.8, including a fresh copy in a
path containing spaces without running initialization. Builds leave declarations,
locks, and other example files unchanged. Example 01's files are unchanged.

The unpacked source hash is
`sha256-ao/kj5UbJ+X0Deywrc5EYkktEy7b3tnfK4IxrLI8eEI=`.
tack's fixed mode instead locks the compressed archive's hash,
`sha256-DV9gFUOC/uELEUocNOeF2LH0kgc64tOm97FHaHs2aqA=`.
These describe different representations of the same release. Source store-path
names can also differ across fetchers, producing different package derivations.
The examples keep those native differences visible; they do not normalize paths
just to force matching derivations.

The observed derivation groups are:

| Approaches | Source path used by the recipe |
| --- | --- |
| Flakes, npins, Lon, Mana, manual | Store directory named `source` |
| niv, Nixtamal | Store directory named `hello-src` |
| tack | `hello` subdirectory of its unpack derivation |

Every group has the same unpacked source hash, greeting, and version. The verifier
prints the individual derivation paths rather than requiring them to match.

## Example 03: A moving Git branch and a locked snapshot

Track [nix-systems/default](https://github.com/nix-systems/default) on `main`,
import its locked Nix list, and write one system per line to `systems.txt`.
The package set stays at the same nixpkgs commit as 01 and 02.

| Approach | Example | Branch declaration |
| --- | --- | --- |
| Nix flakes | [03-git-branch](flake/03-git-branch) | Non-flake input URL ending in `/main` |
| niv | [03-git-branch](niv/03-git-branch) | Separate branch and revision attributes |
| npins | [03-git-branch](npins/03-git-branch) | GitHub branch pin with a seeded revision |
| Lon | [03-git-branch](lon/03-git-branch) | Branch argument plus initial `--revision` |
| Nixtamal | [03-git-branch](nixtamal/03-git-branch) | Freshness command resolves `refs/heads/main` |
| tack | [03-git-branch](tack/03-git-branch) | Source-only manifest URL ending in `/main` |
| Mana | [03-git-branch](mana/03-git-branch) | Raw dependency URL ending in `/main` |
| Manual | [03-git-branch](manual/03-git-branch) | Branch metadata plus commit URL and hash |

The initial lock deliberately uses the historical commit
`da67096a3b9bf56a91d16901293e51ba5b49a27e`, whose list is:

```text
aarch64-darwin
aarch64-linux
x86_64-darwin
x86_64-linux
```

`main` has since removed `x86_64-darwin`. A normal build still produces the four
locked lines. In a disposable copy, run the example's `update.sh`, then rebuild
and `cat result` to see current main. The updater targets only `systems`, leaving
the nixpkgs lock unchanged. The `revision` and `systems-revision` files seed
initialization; builds consume the active commits recorded in the lock.

Use `nix build path:.` for flakes, `nix-build -A systems` for Mana, and `nix-build`
for the others. `result` points to the generated text file. Generated locks and
resolvers are included; no initializer or pinner CLI is needed to build.
Maintenance uses the same tool versions as 01, including Lon 0.8.0.

`./verify-03.sh` checks the initial revisions, the main update target, source
hashes, imported list, output text, matching derivations, and unchanged files.
It intentionally rejects locks updated away from the historical snapshot.
`./verify-03.sh --syntax-only` checks Nix and Bash syntax without building.
The prerequisites match the earlier verification scripts.

Validated on `x86_64-linux` with Nix 2.34.8, including a fresh copy in a path
containing spaces without initialization. All eight produce the same initial
text derivation and leave example files unchanged during builds. In disposable
copies, every updater advanced systems to
`d36eeed142f88b5a636f2e3856a53c61654cf29b`, produced the current three-line list,
and preserved the nixpkgs lock. The checked-in examples retain the initial
four-line snapshot. Examples 01 and 02 are unchanged.

## Example 04: Update only one of two package sets

Each approach exposes `stable` and `unstable`, building Hello from independent
nixpkgs inputs. Stable starts at the same snapshot as examples 01–03;
unstable starts at `34ab99075ac4f7e40cf037eef32cb1c360bb85e9`.
These snapshots illustrate independent selection: the unstable seed predates
the stable seed. Their future update targets are `nixos-26.05` and
`nixpkgs-unstable`. Updating unstable does not imply a new Hello version.

| Approach | Example | Selective command |
| --- | --- | --- |
| flake | [04-selective-updates](flake/04-selective-updates) | `nix flake update --flake path:. unstable` |
| niv | [04-selective-updates](niv/04-selective-updates) | `niv update unstable` |
| npins | [04-selective-updates](npins/04-selective-updates) | `npins update unstable` |
| lon | [04-selective-updates](lon/04-selective-updates) | `lon update unstable` |
| nixtamal | [04-selective-updates](nixtamal/04-selective-updates) | `nixtamal refresh --no-tui unstable` |
| tack | [04-selective-updates](tack/04-selective-updates) | `tack update unstable` |
| mana | [04-selective-updates](mana/04-selective-updates) | `mana update unstable (pinned via tool-ref)` |
| manual | [04-selective-updates](manual/04-selective-updates) | `jq replaces only .unstable after prefetch` |

For flakes, build `nix build path:.#stable --out-link result-stable` and
`nix build path:.#unstable --out-link result-unstable`. For all other approaches,
use `nix-build -A stable -o result-stable` and
`nix-build -A unstable -o result-unstable`. Run either result's `bin/hello`.
All locks and resolvers are included; no initialization is required to build.

`./verify-04.sh` checks the shipped revisions, matching derivations across
approaches, greetings, and unchanged files. It intentionally expects the initial
locks. `./verify-04.sh --syntax-only` checks Nix and Bash syntax.
`./verify-04.sh --updates` additionally updates disposable copies, requires
unstable to advance, and checks that stable's complete lock
entry and Hello derivation remain unchanged. Updated builds must also leave
files unchanged. Its temporary copies are removed automatically. Update copies
use paths with spaces except for Mana: its pinned CLI passes the working
directory as an unquoted Nix expression, so maintenance requires a path without
spaces. Builds from Mana's saved lock work in paths with spaces. This limitation
is documented rather than adding a temporary-copy wrapper to the example.

The update exercise requires all maintenance CLIs, Git, and jq. Run:

```sh
nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/2efa67fd26b6df417c33e4603185c701f260dd83.tar.gz \
  -p niv npins lon nixtamal.bin tack git jq --run './verify-04.sh --updates'
```

The maintenance shell uses the same immutable stable seed. Mana runs its pinned
source itself. If your global Git configuration
rewrites HTTPS URLs to SSH, the previously documented neutral Git environment
also applies to this update exercise.

Validated on `x86_64-linux` with Nix 2.34.8. A fresh copy in a path containing
spaces built all sixteen initial outputs without initialization. All eight
selective updates chose `5adc50831c259f87faeb09ddf930d43597197473`, produced the
same updated unstable Hello derivation, and preserved stable's complete lock
entry and derivation. Both initial and updated builds left their example files
unchanged. ShellCheck and Nix/Bash syntax checks passed. The shipped locks retain
the starting snapshots; examples 01–03 are unchanged. Build artifacts were cleaned.

## Example 05: Temporary local overrides

Reuse the locked `nix-systems/default` snapshot from 03, then substitute an
editable checkout. Each `prepare-local.sh` clones the upstream repository,
checks out `da67096a3b9bf56a91d16901293e51ba5b49a27e`, and adds `riscv64-linux`
to its Nix list. The output is text, so no cross-compilation is involved.
`build-local.sh` uses this working tree for one invocation. A normal build returns
to the saved remote pin while the checkout and its edits remain available.

| Approach | Example | Local override |
| --- | --- | --- |
| flake | [05-local-overrides](flake/05-local-overrides) | `--override-input` plus `--no-write-lock-file` |
| niv | [05-local-overrides](niv/05-local-overrides) | `NIV_OVERRIDE_systems` |
| npins | [05-local-overrides](npins/05-local-overrides) | `NPINS_OVERRIDE_systems` |
| lon | [05-local-overrides](lon/05-local-overrides) | `LON_OVERRIDE_systems` |
| nixtamal | [05-local-overrides](nixtamal/05-local-overrides) | Explicit `systemsPath` argument at the import step |
| tack | [05-local-overrides](tack/05-local-overrides) | Native resolver `overrides.systems` argument |
| mana | [05-local-overrides](mana/05-local-overrides) | Explicit `systemsPath` argument in the entrypoint |
| manual | [05-local-overrides](manual/05-local-overrides) | Explicit `systemsPath` argument instead of the locked archive |

Build the remote output with `nix build path:.` for flakes,
`nix-build -A systems` for Mana, or `nix-build` for the other approaches.
Run `cat result` for the original four-line list. Then run `./prepare-local.sh`,
`./build-local.sh`, and `cat result-local` to see the added fifth line.
Further edits are picked up by the next local build. Running the normal build
again restores the original result without modifying the lock or removing the
checkout. `build-local.sh` optionally accepts an existing checkout path.

The flake command passes an absolute checkout path, inferred as a Git input;
uncommitted tracked-file edits are included, and new files require `git add`.
The environment hooks use legacy impure evaluation. Tack supplies a native
resolver argument. Nixtamal and the pinned Mana importer lack a general raw-source
replacement hook in their generated interfaces; these examples select the path
explicitly in the consumer. No additional library is needed. Per-example READMEs
explain the choices and alternatives, and scripts comment the relevant steps.

All remote locks, resolvers, seed files, and version records are included, copied
from 03. Builds need no pinner CLI or initialization. Preparing a local checkout
needs Git and network access; the neutral Git environment described above applies
if the host rewrites public HTTPS URLs to SSH. Existing checkouts are protected
from accidental replacement. Their Git metadata and local edits are excluded from
version control and preserved by `clean.sh`; only disposable build artifacts
outside the checkouts are cleaned.

`./verify-05.sh` performs the exercise entirely in disposable copies, with spaces
in their paths. It checks remote output, a real checkout at the locked commit,
two uncommitted local edits, matching derivations across approaches, restoration
of the remote pin, unchanged locks and source files during builds, and cleanup
that preserves local source. It does not modify your development checkouts.
It requires Nix, Git, jq, GNU tar and the usual GNU utilities; maintenance CLIs
are unnecessary. `./verify-05.sh --syntax-only` checks Nix and Bash syntax.

Validated on `x86_64-linux` with Nix 2.34.8. All eight approaches produced
matching remote, first local, and second local derivations, then returned to the
original remote output. Locks and example sources stayed unchanged during builds;
checkouts remained unchanged except for the deliberate edits. Tests used fresh
copies in paths containing spaces, without initialization or pinner CLIs.
Checkout preparation refused to overwrite local work, and cleanup preserved
checkout files and links, including a file named `keep.tmp`. ShellCheck and
Nix/Bash syntax checks passed. Examples 01–04 are unchanged.

## Example 06: Use an upstream flake package

Each project builds `patchelf-demo`, a small shell wrapper whose executable comes
from `NixOS/patchelf`’s `packages.<system>.default`. The consumer’s nixpkgs creates
the wrapper; the upstream package keeps its own dependency graph.

The shared upstream snapshot is
[`3e996dbef1fa0658012f8dd290bddcf0302acade`](https://github.com/NixOS/patchelf/tree/3e996dbef1fa0658012f8dd290bddcf0302acade).
The source-only variants separately pin
[flake-compat at `5edf11c44bc78a0d334f6334cdaf7d60d732daab`](https://github.com/NixOS/flake-compat/tree/5edf11c44bc78a0d334f6334cdaf7d60d732daab)
to evaluate outputs from the pinner-resolved source. The parent nixpkgs remains
at the same snapshot as earlier examples. Patchelf’s own lock selects nixpkgs
`c69a9bffbecde46b4b939465422ddc59493d3e4d`; it is deliberately retained.

| Approach | Example | Flake output evaluation |
| --- | --- | --- |
| flake | [06-flake-package](flake/06-flake-package) | Native flake input |
| niv | [06-flake-package](niv/06-flake-package) | Pinned flake-compat adapter |
| npins | [06-flake-package](npins/06-flake-package) | Pinned flake-compat adapter |
| lon | [06-flake-package](lon/06-flake-package) | Pinned flake-compat adapter |
| nixtamal | [06-flake-package](nixtamal/06-flake-package) | Pinned flake-compat adapter |
| tack | [06-flake-package](tack/06-flake-package) | Native flake pin |
| mana | [06-flake-package](mana/06-flake-package) | Pinned flake-compat adapter |
| manual | [06-flake-package](manual/06-flake-package) | Pinned flake-compat adapter |

Build with `nix build path:.` for flakes, `nix-build -A patchelf-demo` for Mana,
and `nix-build` for the others. Run `./result/bin/patchelf-demo --version` for
`patchelf 0.19.2`. No initialization or maintenance tool is required to build.
The README and commented expression in each directory explain the approach,
important boundaries, alternatives, and reproducible initialization commands.

The wrapper demonstrates an upstream flake output used as an input to our own
derivation, rather than importing the repository as a package set or selecting
patchelf from the parent nixpkgs. Flakes and tack handle the upstream flake
natively. The other examples fetch sources and explicitly evaluate the flake
with the adapter. No `follows` rule or upstream lock rewrite is introduced.
The package, overlay, and dependency-sharing cases remain separate examples.

Upstream supports `x86_64-linux`, `i686-linux`, and `aarch64-linux`; the flake
wrapper exports those same systems. The verifier targets `x86_64-linux`.
`./verify-06.sh` checks shared source revisions and hashes, retained upstream
locks, matching package and wrapper derivations, executable dependencies,
argument forwarding, version output, and unchanged files during builds.
`./verify-06.sh --syntax-only` checks Nix and Bash syntax. The full verifier
uses disposable fresh copies in paths with spaces, needs Nix, jq and GNU
utilities, and requires no pinner CLIs. As in earlier examples, Nix needs its
experimental `nix-command` and `flakes` features enabled.

Validated on `x86_64-linux` with Nix 2.34.8. All eight fresh copies built the
same wrapper derivation and referenced the exact package obtained by directly
building the pinned upstream flake output. Every wrapper reported
`patchelf 0.19.2` and forwarded `--print-interpreter` correctly. Source hashes,
compatibility adapter revisions, and upstream locks matched; the parent and
upstream nixpkgs pins stayed separate. Builds left example files unchanged.
Tests used paths containing spaces and required no initialization or pinner CLIs.
ShellCheck and Nix/Bash syntax checks passed. Examples 01–05 are unchanged.

## Example 07: Apply an upstream flake overlay

Use the same [patchelf snapshot](https://github.com/NixOS/patchelf/blob/3e996dbef1fa0658012f8dd290bddcf0302acade/flake.nix)
as 06, now selecting `overlays.default` and applying it when importing the
parent nixpkgs. Build the new `pkgs.patchelf-new` attribute and run its
`bin/patchelf --version` for `patchelf 0.19.2`.

The overlay calls its recipe with the receiving package set, so this package
uses the parent toolchain and build helpers. Its `final` argument is the resulting
package set, which the recipe uses for `callPackage`. Example 06 selected the
already constructed upstream package output and wrapped it. The source revision
and upstream lock are identical in these two examples; their package derivations
can still differ because the package sets differ.

| Approach | Example | Obtaining the overlay |
| --- | --- | --- |
| flake | [07-flake-overlay](flake/07-flake-overlay) | Native flake input |
| niv | [07-flake-overlay](niv/07-flake-overlay) | Same pinned flake-compat adapter as 06 |
| npins | [07-flake-overlay](npins/07-flake-overlay) | Same pinned flake-compat adapter as 06 |
| lon | [07-flake-overlay](lon/07-flake-overlay) | Same pinned flake-compat adapter as 06 |
| nixtamal | [07-flake-overlay](nixtamal/07-flake-overlay) | Same pinned flake-compat adapter as 06 |
| tack | [07-flake-overlay](tack/07-flake-overlay) | Native flake pin |
| mana | [07-flake-overlay](mana/07-flake-overlay) | Same pinned flake-compat adapter as 06 |
| manual | [07-flake-overlay](manual/07-flake-overlay) | Same pinned flake-compat adapter as 06 |

For flakes, run `nix build path:.#patchelf-new` (or `nix build path:.`). For Mana,
run `nix-build -A patchelf-new`; for the others, run `nix-build`. All produce
`result/bin/patchelf`. The attribute’s name does not rename the executable.
The expressions comment the two steps: obtaining the upstream overlay and
passing it through `overlays = [ ... ];` to the parent import. Each README
explains its approach, the relevant boundary, and alternatives considered.

All locks, generated resolvers, seed revisions, and tool-version records are
copied unchanged from 06. Builds require no initialization or maintenance CLIs.
The included initializers reproduce those pins using the same tool setup as 06.
The default overlay adds attributes alongside the original parent `patchelf`;
no input-sharing rule or upstream lock modification is involved. Upstream’s
locked nixpkgs still supplies helper functions used in overlay evaluation.
This example changes the selected package’s build environment, and leaves
upstream input-graph sharing for 08. See the
[Nixpkgs overlay documentation](https://nixos.org/manual/nixpkgs/stable/#chap-overlays)
for the receiving package-set interface.

`./verify-07.sh` uses disposable fresh copies with spaces in their paths. It
checks source pins, upstream locks, matching derivations, successful builds and
version output, the parent standard environment in build inputs, and unchanged
files during builds. It compares the result with 06’s upstream package and the
parent’s existing patchelf, and checks that the overlay adds the new attribute.
`./verify-07.sh --syntax-only` checks Nix and Bash syntax. The full verifier
targets `x86_64-linux` and needs Nix, jq, GNU tar and standard GNU utilities;
it requires no pinner CLIs.

Validated on `x86_64-linux` with Nix 2.34.8. All eight fresh copies produced
the same overlay package derivation and reported `patchelf 0.19.2`. Build-input
inspection confirmed the parent standard environment, and the executable’s
interpreter matched the parent dynamic linker. The result differs from 06’s
upstream package and from the original parent `patchelf` (0.15.2), which remains
unchanged. Patchelf’s build-time test suite passed: 68 passed, 4 skipped, no
failures. Locks, source hashes, and compatibility pins match 06; builds left
example files unchanged. Tests used paths containing spaces without initialization
or pinner CLIs. ShellCheck and Nix/Bash syntax checks passed. Examples 01–06
are unchanged, and the new directories contain no build artifacts.

## Further examples

Examples 01–07 are implemented. The remaining numbers reserve the
following concepts; exact fixtures and commands will be worked out individually.

| Number and name | Concept and task |
| --- | --- |
| 08-transitive-inputs | Make the upstream package use the parent's nixpkgs revision. |
| 09-patches | Patch a small controlled dependency, including an update that invalidates the patch. |
| 10-reproducibility | Explore unused inputs, offline caches, unavailable upstreams, and hash failures. |

For 08, retain the patchelf snapshot from 06 and 07 so the difference focuses on
dependency sharing.
For 10, distinguish cached input evaluation from a build whose full closure is
already available offline. Run destructive failure demonstrations in disposable
copies.

## Conventions

Each README explains the goal, approach, meaningful challenges, commands, and
expected result. Include alternatives actually investigated, explaining why a
library or dependency was not chosen; omit empty challenges/alternatives sections.
Comments explain the purpose of meaningful steps. Keep wrappers, extra tools,
and abstractions out of the examples unless the concept needs them.

The manual baseline shows what automation replaces. nvfetcher is an optional
future addition: its package-source update focus is useful, but distinct from
this initial set of project input managers.
