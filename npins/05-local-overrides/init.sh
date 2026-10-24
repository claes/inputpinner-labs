#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e npins/sources.json ]]; then
  printf '%s\n' 'Already initialized; use ./prepare-local.sh and ./build-local.sh.' >&2
  exit 1
fi
revision=$(cat revision)
systems_revision=$(cat systems-revision)
nix --version > versions.txt
npins --version >> versions.txt
npins init --bare
npins add github NixOS nixpkgs --branch nixos-26.05 --at "$revision"
npins add github nix-systems default --name systems --branch main --at "$systems_revision"
