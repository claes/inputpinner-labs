#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e lock.json ]]; then
  printf '%s\n' 'Already initialized; keep experimental updates in a disposable copy.' >&2
  exit 1
fi
revision=$(cat revision)
patchelf_revision=$(cat patchelf-revision)
adapter_revision=$(cat flake-inputs-revision)
nix --version > versions.txt
# Write commit-specific raw dependencies before asking Mana to lock them.
cat > mana.nix <<EOF
{
  name = "flake-package-consumer";
  entrypoint = ./entrypoint.nix;
  dependencies = {
    nixpkgs = { url = "github:NixOS/nixpkgs/$revision"; entrypoint = null; };
    patchelf = { url = "github:NixOS/patchelf/$patchelf_revision"; entrypoint = null; };
    flake-inputs = { url = "github:fricklerhandwerk/flake-inputs/$adapter_revision"; entrypoint = null; };
  };
}
EOF
tool_ref=$(cat tool-ref)
printf 'mana source: %s\n' "$tool_ref" >> versions.txt
mkdir -p nix
nix run "$tool_ref" -- upgrade
nix run "$tool_ref" -- update
