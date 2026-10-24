#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e npins/sources.json ]]; then
  printf '%s\n' 'Already initialized; keep experimental updates in a disposable copy.' >&2
  exit 1
fi
revision=$(cat revision)
patchelf_revision=$(cat patchelf-revision)
adapter_revision=$(cat flake-inputs-revision)
nix --version > versions.txt
npins --version >> versions.txt
npins init --bare
# Pin the source trees; the adapter is a dependency of the consumer.
npins add github NixOS nixpkgs --name nixpkgs --branch nixos-26.05 --at "$revision"
npins add github NixOS patchelf --name patchelf --branch master --at "$patchelf_revision"
npins add github fricklerhandwerk flake-inputs --name flake-inputs --branch main --at "$adapter_revision"
