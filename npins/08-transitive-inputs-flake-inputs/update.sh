#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Select a fixed alternate parent pin; both packages must follow it.
target=$(cat alternate-revision)
[[ $target =~ ^[0-9a-f]{40}$ ]] || { printf '%s\n' 'Invalid alternate revision.' >&2; exit 1; }
# Replacing this named entry retains the other source pins.
npins add github NixOS nixpkgs --name nixpkgs --branch nixos-26.05 --at "$target"
