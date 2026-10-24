#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# This is a reproducible source update, not a patch repair.
target=$(cat updated-systems-revision)
[[ $target =~ ^[0-9a-f]{40}$ ]] || { printf '%s\n' 'Invalid fixture revision.' >&2; exit 1; }
# Select an exact revision instead of today's moving branch tip.
niv update systems --rev "$target"
