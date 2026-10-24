#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Initialization is deliberate: do not reset an existing experiment's pins.
if [[ -e flake.lock ]]; then
  printf '%s\n' 'Already initialized; use the update instructions in README.md.' >&2
  exit 1
fi
revision=$(cat revision)
nix --version > versions.txt
# Explicit path input also works in exported directories without a Git checkout.
nix flake lock path:. --override-input nixpkgs "github:NixOS/nixpkgs/$revision"
