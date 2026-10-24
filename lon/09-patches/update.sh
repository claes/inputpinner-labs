#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# This is a reproducible source update, not a patch repair.
target=$(cat updated-systems-revision)
[[ $target =~ ^[0-9a-f]{40}$ ]] || { printf '%s\n' 'Invalid fixture revision.' >&2; exit 1; }
# modify supports an exact revision; update follows the moving branch.
lon modify systems --revision "$target"
