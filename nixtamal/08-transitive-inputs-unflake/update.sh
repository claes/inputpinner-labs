#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Select a fixed alternate parent pin; both packages must follow it.
target=$(cat alternate-revision)
[[ $target =~ ^[0-9a-f]{40}$ ]] || { printf '%s\n' 'Invalid alternate revision.' >&2; exit 1; }
# Change only nixpkgs' fixed freshness command, then refresh its lock.
old=$(cat revision)
sed -i 's@\$ echo "'"$old"'"@$ echo "'"$target"'"@' nix/tamal/manifest.kdl
nixtamal refresh --no-tui nixpkgs
