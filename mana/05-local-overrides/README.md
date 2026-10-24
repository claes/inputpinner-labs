# 05: Local overrides with mana

Use an editable checkout of `nix-systems/default`, then return to the remote
pin. The default output is the same four-line `systems.txt` as example 03.

An optional `systemsPath` argument in the entrypoint selects the local raw
source. Without it, the injected systems argument comes from the saved lock.

```sh
nix-build -A systems
cat result
./prepare-local.sh
./build-local.sh
cat result-local
nix-build -A systems
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

The pinned importer exposes manifest and lock parameters but no direct
raw-source replacement hook. Lazy evaluation leaves the remote systems argument
unused during a local build. Building needs no Mana CLI; its maintenance
path-with-spaces limitation from 04 still applies to initialization.

Alternative considered: Supplying a modified in-memory lock to the importer
could use a path source, but would couple this example to Mana’s lock
representation. The explicit entrypoint argument is easier to follow.

Locks and resolvers are included and reuse example 03’s snapshots and tool
versions. No initialization or pinner CLI is needed for these builds. To
regenerate the remote pins in a new copy, use `init.sh` with the same
maintenance tool setup as 03. Preparation needs Git and network access. See the
root README if a host Git configuration rewrites GitHub HTTPS to SSH.

`local-systems/` is ignored by Git and preserved by `../../clean.sh`, including
its local edits. Build output links are disposable. `../../verify-05.sh`
exercises both local edits and restoration in disposable copies, leaving your
checkout alone.
