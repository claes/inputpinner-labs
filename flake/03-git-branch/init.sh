#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e flake.lock ]]; then
  printf '%s\n' 'Already initialized; use ./update.sh in a disposable copy.' >&2
  exit 1
fi
revision=$(cat revision)
systems_revision=$(cat systems-revision)
nix --version > versions.txt
# Seed the historical snapshot once; the manifest still tracks main.
nix flake lock path:. \
  --override-input nixpkgs "github:NixOS/nixpkgs/$revision" \
  --override-input systems "github:nix-systems/default/$systems_revision"
