#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ $# -gt 1 ]]; then
  printf '%s\n' 'Usage: ./build-local.sh [checkout-path]' >&2
  exit 2
fi
# Resolve before passing to Nix; an absolute path also handles spaces safely.
local_dir=$(cd -- "${1:-local-systems}" && pwd -P)
# The entrypoint selects the local raw source before importing its list.
nix-build -A systems --argstr systemsPath "$local_dir" -o result-local
