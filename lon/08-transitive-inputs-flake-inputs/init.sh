#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e lon.lock ]]; then
  printf '%s\n' 'Already initialized; keep experimental updates in a disposable copy.' >&2
  exit 1
fi
revision=$(cat revision)
patchelf_revision=$(cat patchelf-revision)
adapter_revision=$(cat flake-inputs-revision)
nix --version > versions.txt
lon --version >> versions.txt
lon init
# Pin the source trees; the adapter is a dependency of the consumer.
lon add github NixOS/nixpkgs nixos-26.05 --name nixpkgs --revision "$revision"
lon add github NixOS/patchelf master --name patchelf --revision "$patchelf_revision"
lon add github fricklerhandwerk/flake-inputs main --name flake-inputs --revision "$adapter_revision"
