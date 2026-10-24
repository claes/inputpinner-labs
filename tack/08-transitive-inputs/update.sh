#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Select a fixed alternate parent pin; both packages must follow it.
target=$(cat alternate-revision)
[[ $target =~ ^[0-9a-f]{40}$ ]] || { printf '%s\n' 'Invalid alternate revision.' >&2; exit 1; }
sed -i 's@url = "github:NixOS/nixpkgs/[^"]*"@url = "github:NixOS/nixpkgs/'"$target"'"@' .tack/pins.toml
tack update nixpkgs
