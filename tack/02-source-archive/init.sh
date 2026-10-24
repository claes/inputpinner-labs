#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Initialization must not reset an existing experiment's pins.
if [[ -e .tack/pins.lock.json ]]; then
  printf '%s\n' 'Already initialized; use the instructions in README.md.' >&2
  exit 1
fi
revision=$(cat revision)
hello_url="https://ftp.gnu.org/gnu/hello/hello-2.12.3.tar.gz"
nix --version > versions.txt
tack --version >> versions.txt
tack init
tack add nixpkgs "github:NixOS/nixpkgs/$revision" --fetch
# Fixed downloads record the archive-byte hash; the resolver then unpacks it.
tack add hello "$hello_url" --fixed --unpack tarball
