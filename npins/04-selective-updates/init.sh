#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e npins/sources.json ]]; then
  printf '%s\n' 'Already initialized; use ./update.sh in a disposable copy.' >&2
  exit 1
fi
stable_revision=$(cat stable-revision)
unstable_revision=$(cat unstable-revision)
nix --version > versions.txt
npins --version >> versions.txt
npins init --bare
# Two named pins can track different branches of the same repository.
npins add github NixOS nixpkgs --name stable --branch nixos-26.05 --at "$stable_revision"
npins add github NixOS nixpkgs --name unstable --branch nixpkgs-unstable --at "$unstable_revision"
