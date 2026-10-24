#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e lon.lock ]]; then
  printf '%s\n' 'Already initialized; use ./update.sh in a disposable copy.' >&2
  exit 1
fi
stable_revision=$(cat stable-revision)
unstable_revision=$(cat unstable-revision)
nix --version > versions.txt
lon --version >> versions.txt
lon init
# Select initial commits while retaining each branch as its update target.
lon add github NixOS/nixpkgs nixos-26.05 --name stable --revision "$stable_revision"
lon add github NixOS/nixpkgs nixpkgs-unstable --name unstable --revision "$unstable_revision"
