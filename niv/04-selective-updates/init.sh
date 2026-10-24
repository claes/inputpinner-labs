#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e nix/sources.json ]]; then
  printf '%s\n' 'Already initialized; use ./update.sh in a disposable copy.' >&2
  exit 1
fi
stable_revision=$(cat stable-revision)
unstable_revision=$(cat unstable-revision)
nix --version > versions.txt
niv --version >> versions.txt
niv init --no-nixpkgs
# Keep each branch and its selected revision in a separate named entry.
niv add NixOS/nixpkgs --name stable --branch nixos-26.05 --rev "$stable_revision"
niv add NixOS/nixpkgs --name unstable --branch nixpkgs-unstable --rev "$unstable_revision"
