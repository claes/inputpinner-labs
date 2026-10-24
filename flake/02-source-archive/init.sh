#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Initialization must not reset an existing experiment's pins.
if [[ -e flake.lock ]]; then
  printf '%s\n' 'Already initialized; use the instructions in README.md.' >&2
  exit 1
fi
revision=$(cat revision)
nix --version > versions.txt
nix flake lock path:. --override-input nixpkgs "github:NixOS/nixpkgs/$revision"
