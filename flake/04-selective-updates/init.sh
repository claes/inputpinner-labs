#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e flake.lock ]]; then
  printf '%s\n' 'Already initialized; use ./update.sh in a disposable copy.' >&2
  exit 1
fi
stable_revision=$(cat stable-revision)
unstable_revision=$(cat unstable-revision)
nix --version > versions.txt
# Seed both commits without changing the branch declarations.
nix flake lock path:. \
  --override-input stable "github:NixOS/nixpkgs/$stable_revision" \
  --override-input unstable "github:NixOS/nixpkgs/$unstable_revision"
