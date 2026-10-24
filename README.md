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

## Further examples

Only 01 is implemented in this iteration. The remaining numbers reserve the
following concepts; exact fixtures and commands will be worked out individually.

| Number and name | Concept and task |
| --- | --- |
| 02-source-archive | Pin a GNU Hello release archive separately and use it as the package source. |
| 03-git-branch | Pin `nix-systems/default` and generate a text artifact from its list. |
| 04-selective-updates | Build Hello from stable and unstable nixpkgs; update only unstable. |
| 05-local-overrides | Replace the systems input with a local checkout, then restore the remote pin. |
| 06-flake-package | Wrap `NixOS/patchelf`'s `packages.<system>.default` and run `--version`. |
| 07-flake-overlay | Apply patchelf's `overlays.default` to the parent's nixpkgs; build `patchelf-new`. |
| 08-transitive-inputs | Make the upstream package use the parent's nixpkgs revision. |
| 09-patches | Patch a small controlled dependency, including an update that invalidates the patch. |
| 10-reproducibility | Explore unused inputs, offline caches, unavailable upstreams, and hash failures. |

For 06, pin the same patchelf commit everywhere and retain its upstream locks.
Use native flake consumption where supported and a pinned `flake-compat` adapter
for source-only consumers. Keep package, overlay, and dependency-sharing examples
separate. Document limitations where a tool cannot express an equivalent workflow.
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
