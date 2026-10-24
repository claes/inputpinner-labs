#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e nix/sources.json ]]; then
  printf '%s\n' 'Already initialized; keep experimental updates in a disposable copy.' >&2
  exit 1
fi
revision=$(cat revision)
patchelf_revision=$(cat patchelf-revision)
compat_revision=$(cat flake-compat-revision)
nix --version > versions.txt
niv --version >> versions.txt
niv init --no-nixpkgs
# Pin the source trees; the adapter is a dependency of the consumer.
niv add NixOS/nixpkgs --name nixpkgs --branch nixos-26.05 --rev "$revision"
niv add NixOS/patchelf --name patchelf --branch master --rev "$patchelf_revision"
niv add NixOS/flake-compat --name flake-compat --branch master --rev "$compat_revision"
