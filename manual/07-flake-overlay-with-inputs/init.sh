#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ -e pins.json ]]; then
  printf '%s\n' 'Already initialized; use a disposable copy for experiments.' >&2
  exit 1
fi
nix --version > versions.txt
printf '{}\n' > pins.json.tmp
# Hash the unpacked tree, as builtins.fetchTarball does.
revision=$(cat revision)
url="https://github.com/NixOS/nixpkgs/archive/$revision.tar.gz"
sha256=$(nix-prefetch-url --unpack "$url")
jq --arg name 'nixpkgs' --arg revision "$revision" --arg url "$url" --arg sha256 "$sha256" \
  '.[$name] = {revision: $revision, url: $url, sha256: $sha256}' pins.json.tmp > pins.next.tmp
mv pins.next.tmp pins.json.tmp
# Hash the unpacked tree, as builtins.fetchTarball does.
revision=$(cat patchelf-revision)
url="https://github.com/NixOS/patchelf/archive/$revision.tar.gz"
sha256=$(nix-prefetch-url --unpack "$url")
jq --arg name 'patchelf' --arg revision "$revision" --arg url "$url" --arg sha256 "$sha256" \
  '.[$name] = {revision: $revision, url: $url, sha256: $sha256}' pins.json.tmp > pins.next.tmp
mv pins.next.tmp pins.json.tmp
# Hash the unpacked tree, as builtins.fetchTarball does.
revision=$(cat with-inputs-revision)
url="https://github.com/denful/with-inputs/archive/$revision.tar.gz"
sha256=$(nix-prefetch-url --unpack "$url")
jq --arg name 'with-inputs' --arg revision "$revision" --arg url "$url" --arg sha256 "$sha256" \
  '.[$name] = {revision: $revision, url: $url, sha256: $sha256}' pins.json.tmp > pins.next.tmp
mv pins.next.tmp pins.json.tmp
# Hash the unpacked tree, as builtins.fetchTarball does.
revision=$(cat flake-parts-revision)
url="https://github.com/hercules-ci/flake-parts/archive/$revision.tar.gz"
sha256=$(nix-prefetch-url --unpack "$url")
jq --arg name 'flake-parts' --arg revision "$revision" --arg url "$url" --arg sha256 "$sha256" \
  '.[$name] = {revision: $revision, url: $url, sha256: $sha256}' pins.json.tmp > pins.next.tmp
mv pins.next.tmp pins.json.tmp
# Hash the unpacked tree, as builtins.fetchTarball does.
revision=$(cat git-hooks-nix-revision)
url="https://github.com/cachix/git-hooks.nix/archive/$revision.tar.gz"
sha256=$(nix-prefetch-url --unpack "$url")
jq --arg name 'git-hooks-nix' --arg revision "$revision" --arg url "$url" --arg sha256 "$sha256" \
  '.[$name] = {revision: $revision, url: $url, sha256: $sha256}' pins.json.tmp > pins.next.tmp
mv pins.next.tmp pins.json.tmp
# Hash the unpacked tree, as builtins.fetchTarball does.
revision=$(cat upstream-nixpkgs-revision)
url="https://github.com/NixOS/nixpkgs/archive/$revision.tar.gz"
sha256=$(nix-prefetch-url --unpack "$url")
jq --arg name 'upstream-nixpkgs' --arg revision "$revision" --arg url "$url" --arg sha256 "$sha256" \
  '.[$name] = {revision: $revision, url: $url, sha256: $sha256}' pins.json.tmp > pins.next.tmp
mv pins.next.tmp pins.json.tmp
mv pins.json.tmp pins.json
