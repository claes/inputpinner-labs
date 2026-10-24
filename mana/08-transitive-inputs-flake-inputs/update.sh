#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Select a fixed alternate parent pin; both packages must follow it.
target=$(cat alternate-revision)
[[ $target =~ ^[0-9a-f]{40}$ ]] || { printf '%s\n' 'Invalid alternate revision.' >&2; exit 1; }
sed -i 's@github:NixOS/nixpkgs/[^"]*@github:NixOS/nixpkgs/'"$target"'@' mana.nix
nix run "$(cat tool-ref)" -- update nixpkgs
