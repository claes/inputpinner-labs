#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# This is a reproducible source update, not a patch repair.
target=$(cat updated-systems-revision)
[[ $target =~ ^[0-9a-f]{40}$ ]] || { printf '%s\n' 'Invalid fixture revision.' >&2; exit 1; }
# Mana reads the desired commit from its manifest, then updates the named lock.
sed -i 's@github:nix-systems/default/[^"]*@github:nix-systems/default/'"$target"'@' mana.nix
nix run "$(cat tool-ref)" -- update systems
