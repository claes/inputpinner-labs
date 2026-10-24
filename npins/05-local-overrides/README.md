# 05: Local overrides with npins

Use an editable checkout of `nix-systems/default`, then return to the remote
pin. The default output is the same four-line `systems.txt` as example 03.

Set `NPINS_OVERRIDE_systems` for one `nix-build` invocation. The generated
resolver supplies the working directory as the systems source.

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

The suffix matches the case-sensitive pin name. Reading this variable requires
impure evaluation, as provided by legacy `nix-build`.

Alternative considered: A caller-side source replacement would also work, but
the generated resolver already provides the required override without another
argument or library.

Locks and resolvers are included and reuse example 03’s snapshots and tool
versions. No initialization or pinner CLI is needed for these builds. To
regenerate the remote pins in a new copy, use `init.sh` with the same
maintenance tool setup as 03. Preparation needs Git and network access. See the
root README if a host Git configuration rewrites GitHub HTTPS to SSH.

`local-systems/` is ignored by Git and preserved by `../../clean.sh`, including
its local edits. Build output links are disposable. `../../verify-05.sh`
exercises both local edits and restoration in disposable copies, leaving your
checkout alone.
