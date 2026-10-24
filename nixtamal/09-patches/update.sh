#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# This is a reproducible source update, not a patch repair.
target=$(cat updated-systems-revision)
[[ $target =~ ^[0-9a-f]{40}$ ]] || { printf '%s\n' 'Invalid fixture revision.' >&2; exit 1; }
# The fixture's freshness command intentionally selects an immutable commit.
old=$(cat systems-revision)
sed -i 's@\$ echo "'"$old"'"@$ echo "'"$target"'"@' nix/tamal/manifest.kdl
nixtamal refresh --no-tui systems
