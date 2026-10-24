#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# This is a reproducible source update, not a patch repair.
target=$(cat updated-systems-revision)
[[ $target =~ ^[0-9a-f]{40}$ ]] || { printf '%s\n' 'Invalid fixture revision.' >&2; exit 1; }
# Change the desired source URL, then relock only systems.
sed -i 's@url = "github:nix-systems/default/[^"]*"@url = "github:nix-systems/default/'"$target"'"@' .tack/pins.toml
tack update systems
