#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e flake.lock ]]; then
  printf '%s\n' 'Already initialized; keep experimental updates in a disposable copy.' >&2
  exit 1
fi
revision=$(cat revision)
patchelf_revision=$(cat patchelf-revision)
nix --version > versions.txt
# Seed parent and upstream separately; Nix retains the upstream child locks.
nix flake lock path:. \
  --override-input nixpkgs "github:NixOS/nixpkgs/$revision" \
  --override-input patchelf "github:NixOS/patchelf/$patchelf_revision"
