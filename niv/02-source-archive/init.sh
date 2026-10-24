#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Initialization must not reset an existing experiment's pins.
if [[ -e nix/sources.json ]]; then
  printf '%s\n' 'Already initialized; use the instructions in README.md.' >&2
  exit 1
fi
revision=$(cat revision)
hello_url="https://ftp.gnu.org/gnu/hello/hello-2.12.3.tar.gz"
nix --version > versions.txt
niv --version >> versions.txt
niv init --no-nixpkgs
niv add NixOS/nixpkgs --name nixpkgs --branch nixos-26.05 --rev "$revision"
# A versioned tarball needs neither a Git repository nor release discovery.
niv add hello --type tarball --template "$hello_url"
