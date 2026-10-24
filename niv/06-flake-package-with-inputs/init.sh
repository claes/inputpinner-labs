#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e nix/sources.json ]]; then
  printf '%s\n' 'Already initialized; use a disposable copy for experiments.' >&2
  exit 1
fi
nix --version > versions.txt
niv --version >> versions.txt
niv init --no-nixpkgs
niv add NixOS/nixpkgs --name nixpkgs --branch nixos-26.05 --rev "$(cat revision)"
niv add NixOS/patchelf --name patchelf --branch master --rev "$(cat patchelf-revision)"
niv add denful/with-inputs --name with-inputs --branch main --rev "$(cat with-inputs-revision)"
niv add hercules-ci/flake-parts --name flake-parts --branch main --rev "$(cat flake-parts-revision)"
niv add cachix/git-hooks.nix --name git-hooks-nix --branch master --rev "$(cat git-hooks-nix-revision)"
niv add NixOS/nixpkgs --name upstream-nixpkgs --branch nixpkgs-unstable --rev "$(cat upstream-nixpkgs-revision)"
