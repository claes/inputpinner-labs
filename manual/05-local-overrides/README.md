# 05: Local overrides with manual

Use an editable checkout of `nix-systems/default`, then return to the remote
pin. The default output is the same four-line `systems.txt` as example 03.

An optional `systemsPath` argument selects the local directory instead of the
archive stored in `pins.json`. The fixed nixpkgs input still builds the text
file.

```sh
nix-build
cat result
./prepare-local.sh
./build-local.sh
cat result-local
nix-build
cat result
```

Preparation clones upstream, checks out the exact `systems-revision`, and edits
`default.nix` to add `riscv64-linux`. This changes list data; it does not build
packages for that platform. The checkout is deliberately dirty and editable.
Preparation refuses to replace an existing `local-systems` directory.

The local result has five lines. Edit the checkout and repeat `./build-local.sh`
to see further changes. The normal build returns to the original four lines,
even while the edited checkout exists. The override is scoped to one invocation;
no restore command or lock rewrite is required. You can also pass another
checkout as `./build-local.sh /absolute/path/to/checkout`.

Local development intentionally bypasses the systems archive hash. The saved
remote URL, revision, and hash remain unchanged and resume applying when the
argument is omitted.

Alternative considered: An environment-variable convention could automate path
selection. An explicit argument keeps the manual baseline independent of any
tool-specific convention.

Locks and resolvers are included and reuse example 03’s snapshots and tool
versions. No initialization or pinner CLI is needed for these builds. To
regenerate the remote pins in a new copy, use `init.sh` with the same
maintenance tool setup as 03. Preparation needs Git and network access. See the
root README if a host Git configuration rewrites GitHub HTTPS to SSH.

`local-systems/` is ignored by Git and preserved by `../../clean.sh`, including
its local edits. Build output links are disposable. `../../verify-05.sh`
exercises both local edits and restoration in disposable copies, leaving your
checkout alone.
