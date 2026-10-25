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

## Example 06: Use an upstream flake package with flake libraries

Build `patchelf-demo`, a wrapper around upstream’s `packages.<system>.default`.
The parent nixpkgs creates the wrapper; patchelf uses its original nixpkgs
revision (`c69a9bffbecde46b4b939465422ddc59493d3e4d`). All variants preserve
that separation and produce the same wrapper and upstream package.

The six source-only pinners have variants explicitly named
`-flake-compat`, `-flake-inputs`, `-unflake` and `-with-inputs`. Flakes and tack retain one native reference.
The original two adapters are pinned: [flake-compat](https://github.com/NixOS/flake-compat/tree/5edf11c44bc78a0d334f6334cdaf7d60d732daab)
and [flake-inputs](https://github.com/fricklerhandwerk/flake-inputs/tree/5c1279c5b5dc81dfd245fc4d072446fc56f341c7).
The parent nixpkgs remains `2efa67fd26b6df417c33e4603185c701f260dd83`; patchelf
remains `3e996dbef1fa0658012f8dd290bddcf0302acade`. New variants include native
locks, resolvers and version records, so normal consumption needs no initializer
or maintenance CLI. Existing artifacts move with renamed flake-compat directories;
the pre-existing Nixtamal 07 `result` symlink was preserved there.

| Approach | Variant(s) |
| --- | --- |
| flake | [native](flake/06-flake-package) |
| niv | [flake-compat](niv/06-flake-package-flake-compat), [flake-inputs](niv/06-flake-package-flake-inputs), [unflake](niv/06-flake-package-unflake), [with-inputs](niv/06-flake-package-with-inputs) |
| npins | [flake-compat](npins/06-flake-package-flake-compat), [flake-inputs](npins/06-flake-package-flake-inputs), [unflake](npins/06-flake-package-unflake), [with-inputs](npins/06-flake-package-with-inputs) |
| lon | [flake-compat](lon/06-flake-package-flake-compat), [flake-inputs](lon/06-flake-package-flake-inputs), [unflake](lon/06-flake-package-unflake), [with-inputs](lon/06-flake-package-with-inputs) |
| nixtamal | [flake-compat](nixtamal/06-flake-package-flake-compat), [flake-inputs](nixtamal/06-flake-package-flake-inputs), [unflake](nixtamal/06-flake-package-unflake), [with-inputs](nixtamal/06-flake-package-with-inputs) |
| tack | [native](tack/06-flake-package) |
| mana | [flake-compat](mana/06-flake-package-flake-compat), [flake-inputs](mana/06-flake-package-flake-inputs), [unflake](mana/06-flake-package-unflake), [with-inputs](mana/06-flake-package-with-inputs) |
| manual | [flake-compat](manual/06-flake-package-flake-compat), [flake-inputs](manual/06-flake-package-flake-inputs), [unflake](manual/06-flake-package-unflake), [with-inputs](manual/06-flake-package-with-inputs) |

flake-compat returns `.outputs` from its imported adapter; flake-inputs uses
`.import-flake { src = sources.patchelf; }`. Neither variant overrides an input
or rewrites a lock, and both work with IFD disabled. Comments show source
resolution, adapter evaluation, package selection and the wrapper’s runtime
reference to that package.

Build with `nix build path:.` for flakes, `nix-build -A patchelf-demo` for Mana
and with-inputs, and `nix-build` for the other source variants. Run `./result/bin/patchelf-demo --version` for
`patchelf 0.19.2`. The wrapper forwards arguments to the upstream executable.

`./verify-06.sh` checks all 26 implementations against the directly evaluated
upstream flake: source pins and hashes, unchanged upstream locks, package and
wrapper derivations, executable dependencies, argument forwarding and unchanged
project files during builds. `--syntax-only` checks Nix and Bash syntax.

Validated on `x86_64-linux` with Nix 2.34.8: all 26 implementations produced
the same wrapper and referenced the original upstream package. All variants
retained upstream’s independent nixpkgs revision. IFD was enabled only for
Nixtamal/with-inputs, whose native loader reads build-time fetcher outputs.
The flake-inputs initializers regenerated matching pins and built successfully
for all six source-only pinners in disposable copies.

### Unflake variants in examples 06–08

[Unflake](https://codeberg.org/goldstein/unflake) generates dependency injection
code as well as resolving a graph. It ignores dependency `flake.lock` files,
so its variants explicitly seed the transitive revisions instead of silently
resolving moving branches. The tool is fixed at
`22d908471bf3201856cd10d22813d85c66a75907` in each `unflake-tool-ref`.

npins uses the supported backend directly. The other five pinners use a small
local source bridge: initialization generates using npins in a temporary
directory, imports the pins into the chosen pinner and replaces only the
generated backend import. Builds fetch exclusively through that pinner and
need neither npins nor unflake installed. The bridge is maintained by this lab;
it is not an upstream-supported backend. No extra runtime library or IFD is
needed. Each example includes its generated evaluator and native locks.

Calling unflake’s internal Python generator directly is another possible
integration, avoiding the temporary npins stage. It would require maintaining
a custom backend against an internal API; this lab retains the CLI-based route.
Unflake does not expose a standalone Nix importer like flake-inputs.

The pinned unflake version ignores nested overrides. Its generated graph
therefore includes git-hooks’ gitignore and flake-compat sources, which the
native reference avoids through empty follows. Explicit rules unify the
relevant nixpkgs spellings, including registry and tarball references. In 06/07
they select the original upstream nixpkgs separately from our parent; in 08
they select the parent for every edge. The incidental flake-compat source is
not used as the evaluator in these variants.

The existing verifiers invoke `verify-unflake.sh` to add six cases per exercise,
alongside six with-inputs cases, for 26 implementations each. Example 08 also checks a fifth edge through
gitignore, and its update check requires the generated evaluator to stay
unchanged while only the native parent pin changes. Initialization requires
npins for generation plus the chosen pinner (and Nix/jq); per-example READMEs
provide commands and discuss the alternatives.

All 18 unflake variants were initialized with the pinned tools and passed their
build checks. The source mapping covers every dependency exactly once; npins’
`__functor` helper is metadata rather than a dependency. In 08 all six parent-only
updates changed both package derivations while leaving the evaluator unchanged.
Consumption also passed from fresh copies in paths containing spaces, without
initialization or unflake installed, and with IFD disabled.

### Direct evaluation with with-inputs

The `-with-inputs` variants use
[denful/with-inputs](https://github.com/denful/with-inputs/tree/641d01ef95eae1aeaa257ffd48102ab9a308f2a2)
and its complete sources → follows → outputs interface. Each example keeps
source loading, `follows` and `outputs` together in one file, with named bindings
that make each step visible. Nixtamal finishes with `with-inputs follows outputs`.
The other pinners retain `with-inputs [ follows inputsOverrides ] outputs` for
caller overrides. The loader binds sources first. `system` remains optional. The public result includes `.inputs`,
`.outputs` and project `self`, alongside the named packages.

Niv, npins, Lon and Nixtamal use the built-in `.from.*` loaders. Nixtamal uses
the upstream declaration directly:

```nix
with-inputs =
  (import (import ./nix/tamal {}).with-inputs).from.nixtamal ./.;
```

Its archives use `fetch-time=build`, giving the loader native source records.
Reading flake files from these outputs requires **IFD (Import From Derivation)**:
evaluation can build source fetchers before defining the packages. Add
`--option allow-import-from-derivation true` to these Nixtamal build commands.
Evaluation-time archives plus a source conversion remain a documented
alternative; the native loader is chosen for a simpler example.

Mana uses its native dependency injection, and manual uses its recorded archive
fetches. They bind sources and project `self` through the generic API. All
teaching logic stays in `default.nix`, or Mana's existing `entrypoint.nix`; no
extra bootstrap, follows or outputs files are added.

Nixtamal keeps the package-consumption examples small: four pins in 06/07 and
three in 08, with one follows declaration each. Patchelf's packages and overlay
do not evaluate its development tooling, so these examples omit flake-parts,
git-hooks-nix and their input wiring. In 06/07 the consumed upstream nixpkgs is
`upstream-nixpkgs`; in 08 it follows the parent `nixpkgs`.

The other pinners retain six pins in 06/07 and five in 08, including development
inputs and their aliases/disconnections. Automatic input matching and the
library's `from.flake` fetcher are documented alternatives.

Build all six pinners' 06 variants with `nix-build -A patchelf-demo`, and 07 with
`nix-build -A patchelf-new`. Example 08 keeps `-A hello` and `-A patchelf`.
`verify-with-inputs.sh` inspects public inputs and named outputs directly,
including `inputs.self`, native pin preservation, caller overrides where supported, and parent-only
updates in 08. It checks matching derivations and builds, compiler dependencies,
and immutable files in fresh copies with spaces in their paths. Only the three
Nixtamal/with-inputs cases enable IFD; the other with-inputs cases disable it.
All consume the shipped native resolver without a maintenance CLI.

## Example 07: Apply an upstream flake overlay with flake libraries

Obtain `overlays.default` from the upstream flake and pass it to the parent
nixpkgs import. Build `pkgs.patchelf-new`, whose recipe now uses the parent’s
compiler, libraries and build helpers. The overlay adds an attribute alongside
the parent’s original patchelf. Upstream’s own lock remains unchanged; this is
recipe composition rather than input-graph sharing.

| Approach | Variant(s) |
| --- | --- |
| flake | [native](flake/07-flake-overlay) |
| niv | [flake-compat](niv/07-flake-overlay-flake-compat), [flake-inputs](niv/07-flake-overlay-flake-inputs), [unflake](niv/07-flake-overlay-unflake), [with-inputs](niv/07-flake-overlay-with-inputs) |
| npins | [flake-compat](npins/07-flake-overlay-flake-compat), [flake-inputs](npins/07-flake-overlay-flake-inputs), [unflake](npins/07-flake-overlay-unflake), [with-inputs](npins/07-flake-overlay-with-inputs) |
| lon | [flake-compat](lon/07-flake-overlay-flake-compat), [flake-inputs](lon/07-flake-overlay-flake-inputs), [unflake](lon/07-flake-overlay-unflake), [with-inputs](lon/07-flake-overlay-with-inputs) |
| nixtamal | [flake-compat](nixtamal/07-flake-overlay-flake-compat), [flake-inputs](nixtamal/07-flake-overlay-flake-inputs), [unflake](nixtamal/07-flake-overlay-unflake), [with-inputs](nixtamal/07-flake-overlay-with-inputs) |
| tack | [native](tack/07-flake-overlay) |
| mana | [flake-compat](mana/07-flake-overlay-flake-compat), [flake-inputs](mana/07-flake-overlay-flake-inputs), [unflake](mana/07-flake-overlay-unflake), [with-inputs](mana/07-flake-overlay-with-inputs) |
| manual | [flake-compat](manual/07-flake-overlay-flake-compat), [flake-inputs](manual/07-flake-overlay-flake-inputs), [unflake](manual/07-flake-overlay-unflake), [with-inputs](manual/07-flake-overlay-with-inputs) |

The source pins and adapter revisions match the corresponding 06 variant.
Only Nixtamal/with-inputs needs IFD to load its build-time source fetches. Each README explains its
selected interface and alternatives, including the generated unflake evaluator and direct with-inputs evaluation.

Build with `nix build path:.#patchelf-new` for flakes,
`nix-build -A patchelf-new` for Mana and with-inputs, and `nix-build` otherwise. Run
`./result/bin/patchelf --version` for `patchelf 0.19.2`; the attribute name does
not rename the executable.

`./verify-07.sh` checks all 26 implementations for identical overlay packages,
parent build dependencies and dynamic linker, retained source pins and upstream
locks, the added attribute, preservation of the original package and unchanged
files during builds. It distinguishes the result from 06’s upstream package.
`--syntax-only` checks Nix and Bash syntax.

Validated on `x86_64-linux` with Nix 2.34.8: all 26 implementations produced
the same overlay package with the parent standard environment and dynamic linker.
The original parent package and upstream source trees stayed unchanged. IFD
was enabled only for Nixtamal/with-inputs; the other variants, including the
generated unflake evaluators, passed with it disabled.

## Example 08: Hello and upstream patchelf share nixpkgs

This merges the former 08 and 10 sharing exercises. Pin nixpkgs once, obtain
Hello from it, and make patchelf’s flake use the same chosen source. Every
implementation exposes `hello` and `patchelf` directly, without a wrapper.

| Approach | Variant(s) |
| --- | --- |
| flake | [native](flake/08-transitive-inputs) |
| niv | [flake-compat](niv/08-transitive-inputs-flake-compat), [flake-inputs](niv/08-transitive-inputs-flake-inputs), [unflake](niv/08-transitive-inputs-unflake), [with-inputs](niv/08-transitive-inputs-with-inputs) |
| npins | [flake-compat](npins/08-transitive-inputs-flake-compat), [flake-inputs](npins/08-transitive-inputs-flake-inputs), [unflake](npins/08-transitive-inputs-unflake), [with-inputs](npins/08-transitive-inputs-with-inputs) |
| lon | [flake-compat](lon/08-transitive-inputs-flake-compat), [flake-inputs](lon/08-transitive-inputs-flake-inputs), [unflake](lon/08-transitive-inputs-unflake), [with-inputs](lon/08-transitive-inputs-with-inputs) |
| nixtamal | [flake-compat](nixtamal/08-transitive-inputs-flake-compat), [flake-inputs](nixtamal/08-transitive-inputs-flake-inputs), [unflake](nixtamal/08-transitive-inputs-unflake), [with-inputs](nixtamal/08-transitive-inputs-with-inputs) |
| tack | [native](tack/08-transitive-inputs) |
| mana | [flake-compat](mana/08-transitive-inputs-flake-compat), [flake-inputs](mana/08-transitive-inputs-flake-inputs), [unflake](mana/08-transitive-inputs-unflake), [with-inputs](mana/08-transitive-inputs-with-inputs) |
| manual | [flake-compat](manual/08-transitive-inputs-flake-compat), [flake-inputs](manual/08-transitive-inputs-flake-inputs), [unflake](manual/08-transitive-inputs-unflake), [with-inputs](manual/08-transitive-inputs-with-inputs) |

Native flakes use `patchelf.inputs.nixpkgs.follows = "nixpkgs"`. Tack uses
`all_follow`, including upstream’s `nixpkgs-lib` and `nixpkgs-stable` aliases.
Its name-based rule applies at every depth and should be reviewed when adding
other inputs.

The flake-inputs variants express the relationship directly:

```nix
pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
upstream = (import sources.flake-inputs).import-flake {
  src = sources.patchelf;
  overrides.nixpkgs = sources.nixpkgs;
};
# Expose pkgs.hello and upstream.packages.${system}.default.
```

Existing upstream follows chains reach that same source. This needs no lock
rewrite, staging build or IFD. The adapter’s path overrides omit some metadata:
reading the overridden `narHash` is unsupported, so hash its resolved path.

The pinned flake-compat has no override parameter. Its variants retain the
commented `share-nixpkgs.nix` helper, staging upstream with its existing nixpkgs
lock node replaced using the active parent revision and resolved source hash.
Other lock fields and original source trees stay unchanged. Importing that
staged tree needs `allow-import-from-derivation = true`. The helper is specific
to this fixture’s GitHub pin and version-7 lock. It may fetch the same source
under a different native basename; this introduces no independent version choice.
This extra machinery is the main difference between the two equivalent variants.

For flakes, build both packages with:

```sh
nix build path:.#hello --out-link result-hello
nix build path:.#patchelf --out-link result-patchelf
```

For every other pinner, including Mana:

```sh
nix-build -A hello -o result-hello
nix-build -A patchelf -o result-patchelf
```

Run `./result-hello/bin/hello` and `./result-patchelf/bin/patchelf --version`
for `Hello, world!` and `patchelf 0.19.2`. In a disposable copy, `./update.sh`
selects the fixed older nixpkgs in `alternate-revision`. Rebuild and compare
`readlink result-hello result-patchelf`: both paths change while patchelf’s
source and version stay fixed. The initialization seed `revision` stays unchanged.
The READMEs describe maintenance requirements. Mana maintenance needs a path
without spaces; its saved locks build correctly in spaced paths.

`./verify-08.sh` checks all 26 implementations, including both packages’ actual
build dependencies and effective upstream nixpkgs references. Nixtamal/with-inputs
checks the consumed patchelf nixpkgs edge; the other variants also inspect
their configured development-input edges. It compares
source hashes when native fetch names differ, checks direct path reuse for
flake-inputs, unflake and with-inputs, and checks that staged trees differ only in the intended
lock node. Unflake also checks the gitignore nixpkgs edge and all source mappings.
IFD is enabled only for staged flake-compat and Nixtamal/with-inputs cases.
All other cases disable it. `--updates` exercises changes to the parent pin across all 26 cases,
requiring other pins and original upstream locks to stay unchanged.
`--syntax-only` checks Nix and Bash syntax.

All three verifiers use disposable fresh copies in paths containing spaces,
target `x86_64-linux` and need Nix, jq and GNU utilities. Normal verification
needs no maintenance CLIs. For the optional 08 update checks:

```sh
nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/2efa67fd26b6df417c33e4603185c701f260dd83.tar.gz \
  -p niv npins lon nixtamal.bin tack --run './verify-08.sh --updates'
```

Validated on `x86_64-linux` with Nix 2.34.8: all 26 sharing implementations
passed with both parent pins, producing matching Hello and patchelf derivations
at each pin. Only the parent pin changed; upstream and adapter records stayed
fixed. All effective input edges matched the parent source contents, including
the fifth edge through gitignore in unflake, and both packages used the parent
standard environment. Staged compatibility trees differed
only in the intended lock node. IFD was enabled only for staged flake-compat
and Nixtamal/with-inputs cases; all other cases passed with it disabled. Builds left
project files and upstream sources unchanged. Syntax checks and ShellCheck
passed for all three flake-related exercises. Examples 01–05 and 09, existing
`.gitignore` edits and the moved Nixtamal result link were preserved.

## Example 09: Patch a pinned dependency and repair after an update

Each [09-patches](manual/09-patches/README.md) example reuses 03’s small
`nix-systems/default` source. A local patch replaces `x86_64-darwin` with
`riscv64-linux`. The normal Nixpkgs patch phase runs in an unpacked build copy;
the original source pin and its fetch hash remain unchanged. The artifact is a
single Nix file containing the patched list. No compiler, adapter library or
import-from-derivation is needed.

| Approach | Example | Fixed source update |
| --- | --- | --- |
| flake | [09-patches](flake/09-patches) | Override just the systems lock |
| niv | [09-patches](niv/09-patches) | Update systems with an explicit revision |
| npins | [09-patches](npins/09-patches) | Replace the named pin with `--at` |
| lon | [09-patches](lon/09-patches) | Modify systems with an explicit revision |
| nixtamal | [09-patches](nixtamal/09-patches) | Change the freshness command, refresh systems |
| tack | [09-patches](tack/09-patches) | Change the manifest URL, update systems |
| mana | [09-patches](mana/09-patches) | Change the manifest URL, update systems |
| manual | [09-patches](manual/09-patches) | Fetch the archive, replace systems URL/revision/hash |

Build with `nix build path:.` for flakes, `nix-build -A systems` for Mana,
and `nix-build` for the others. Read the file with `cat result`, or evaluate the
completed artifact with `nix eval --json --file ./result`. Its list contains
`aarch64-darwin`, `aarch64-linux`, `riscv64-linux`, and `x86_64-linux`.

In a disposable copy, `./update.sh` selects the immutable second fixture recorded
in `updated-systems-revision`. That upstream commit already removed the entry
our original patch replaces. Source locking succeeds, but the next build must
fail with a rejected patch hunk. Review upstream’s change and the supplied
`local.after-update.patch`, then explicitly copy it to `local.patch` and rebuild.
The repaired patch adds the desired entry, restoring the same final list.
Updates never drop or repair patches automatically; nixpkgs stays pinned.
Per-example READMEs include maintenance CLI bootstrap commands and alternatives
considered, including Nixtamal’s native patch management.

`./verify-09.sh` builds the shipped state in disposable copies whose paths contain
spaces, without initialization or pinner CLIs. `./verify-09.sh --updates` also
runs all native update commands, confirms the specific patch-hunk rejection,
and tests the explicit repair. It checks exact source revisions and hashes,
identical output bytes and evaluated lists, retained nixpkgs records, and unchanged
project files during both successful and failed builds. Strict patch flags disable
fuzz and reverse application. Derivations are compared within each native source
path group: niv and Nixtamal use `systems-src`, while the other tools use `source`.
Their fetched contents and patched artifacts match despite differing store paths.
Mana maintenance temporarily uses a path without spaces because of its pinned
CLI’s cwd quoting bug; its builds still run in the spaced path.
`./verify-09.sh --syntax-only` checks Nix and Bash syntax. Full verification
targets `x86_64-linux` and needs Nix, jq, GNU utilities, and (only for `--updates`)
the maintenance CLIs:

```sh
nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/2efa67fd26b6df417c33e4603185c701f260dd83.tar.gz \
  -p niv npins lon nixtamal.bin tack --run './verify-09.sh --updates'
```

Validated on `x86_64-linux` with Nix 2.34.8. All eight starting builds passed,
all eight fixed updates produced the intended patch-hunk failure, and all eight
explicit repairs restored identical output contents. Native nixpkgs records
remained unchanged. Builds used paths containing spaces and left declarations,
locks, and patches untouched. Initial derivations formed two source-path groups;
outputs matched across both. The three adapted initializers (Nixtamal, tack and
Mana) also regenerated the starting pins and built successfully in fresh copies.
ShellCheck and Nix/Bash syntax checks passed. Examples 01–08 are unchanged, and the new directories contain no build artifacts.

## Further examples

Examples 01–09 are implemented. The remaining numbers reserve the
following concepts; exact fixtures and commands will be worked out individually.

| Number and name | Concept and task |
| --- | --- |
| 10-reproducibility | Explore unused inputs, offline caches, unavailable upstreams, and hash failures. |

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
