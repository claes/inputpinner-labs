#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Initialization must not reset an existing experiment's pins.
if [[ -e npins/sources.json ]]; then
  printf '%s\n' 'Already initialized; use the instructions in README.md.' >&2
  exit 1
fi
revision=$(cat revision)
hello_url="https://ftp.gnu.org/gnu/hello/hello-2.12.3.tar.gz"
nix --version > versions.txt
npins --version >> versions.txt
npins init --bare
npins add github NixOS nixpkgs --branch nixos-26.05 --at "$revision"
npins add tarball "$hello_url" --name hello
