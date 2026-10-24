#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ $# -gt 1 ]]; then
  printf '%s\n' 'Usage: ./build-local.sh [checkout-path]' >&2
  exit 2
fi
# Resolve before passing to Nix; an absolute path also handles spaces safely.
local_dir=$(cd -- "${1:-local-systems}" && pwd -P)
# The generated resolver reads this variable during impure legacy evaluation.
NIV_OVERRIDE_systems="$local_dir" nix-build -o result-local
