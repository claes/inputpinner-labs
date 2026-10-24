#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Initialization must not reset an existing experiment's pins.
if [[ -e lon.lock ]]; then
  printf '%s\n' 'Already initialized; use the instructions in README.md.' >&2
  exit 1
fi
revision=$(cat revision)
hello_url="https://ftp.gnu.org/gnu/hello/hello-2.12.3.tar.gz"
nix --version > versions.txt
# Lon 0.8.0 from example 01 lacks tarball inputs; use this pinned newer tool.
tool_ref=$(cat tool-ref)
nix run "$tool_ref" -- --version >> versions.txt
printf 'lon source: %s\n' "$tool_ref" >> versions.txt
nix run "$tool_ref" -- init
nix run "$tool_ref" -- add github NixOS/nixpkgs nixos-26.05 --revision "$revision"
nix run "$tool_ref" -- add tarball hello "$hello_url"
