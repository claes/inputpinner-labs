#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e lock.json ]]; then
  printf '%s\n' 'Already initialized; use a disposable copy for experiments.' >&2
  exit 1
fi
nix --version > versions.txt
cat > mana.nix <<EOF
{
  name = "flake-overlay-consumer";
  entrypoint = ./entrypoint.nix;
  dependencies = {
    nixpkgs = { url = "github:NixOS/nixpkgs/$(cat revision)"; entrypoint = null; };
    patchelf = { url = "github:NixOS/patchelf/$(cat patchelf-revision)"; entrypoint = null; };
    with-inputs = { url = "github:denful/with-inputs/$(cat with-inputs-revision)"; entrypoint = null; };
    flake-parts = { url = "github:hercules-ci/flake-parts/$(cat flake-parts-revision)"; entrypoint = null; };
    git-hooks-nix = { url = "github:cachix/git-hooks.nix/$(cat git-hooks-nix-revision)"; entrypoint = null; };
    upstream-nixpkgs = { url = "github:NixOS/nixpkgs/$(cat upstream-nixpkgs-revision)"; entrypoint = null; };
  };
}
EOF
tool_ref=$(cat tool-ref)
printf 'mana source: %s\n' "$tool_ref" >> versions.txt
mkdir -p nix
nix run "$tool_ref" -- upgrade
nix run "$tool_ref" -- update
