#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e npins/sources.json ]]; then
  printf '%s\n' 'Already initialized; use a disposable copy for experiments.' >&2
  exit 1
fi
nix --version > versions.txt
npins --version >> versions.txt
npins init --bare
npins add github NixOS nixpkgs --name nixpkgs --branch nixos-26.05 --at "$(cat revision)"
npins add github NixOS patchelf --name patchelf --branch master --at "$(cat patchelf-revision)"
npins add github denful with-inputs --name with-inputs --branch main --at "$(cat with-inputs-revision)"
npins add github hercules-ci flake-parts --name flake-parts --branch main --at "$(cat flake-parts-revision)"
npins add github cachix git-hooks.nix --name git-hooks-nix --branch master --at "$(cat git-hooks-nix-revision)"
