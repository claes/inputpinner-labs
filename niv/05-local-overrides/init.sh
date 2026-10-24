#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e nix/sources.json ]]; then
  printf '%s\n' 'Already initialized; use ./prepare-local.sh and ./build-local.sh.' >&2
  exit 1
fi
revision=$(cat revision)
systems_revision=$(cat systems-revision)
nix --version > versions.txt
niv --version >> versions.txt
niv init --no-nixpkgs
niv add NixOS/nixpkgs --name nixpkgs --branch nixos-26.05 --rev "$revision"
# The update branch and selected commit are separate attributes.
niv add nix-systems/default --name systems --branch main --rev "$systems_revision"
