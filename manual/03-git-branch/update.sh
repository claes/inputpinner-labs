#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Refresh the tracked systems branch; a normal build never changes its lock.
# Resolve only the tracked systems branch; keep nixpkgs untouched.
branch=$(jq -r .systems.branch pins.json)
systems_revision=$(git ls-remote https://github.com/nix-systems/default.git "refs/heads/$branch" | cut -f1)
[[ $systems_revision =~ ^[0-9a-f]{40}$ ]] || { printf '%s\n' 'Branch lookup did not return a commit.' >&2; exit 1; }
systems_url="https://github.com/nix-systems/default/archive/$systems_revision.tar.gz"
systems_hash=$(nix-prefetch-url --unpack "$systems_url")
jq --arg revision "$systems_revision" --arg url "$systems_url" --arg sha256 "$systems_hash" \
  '.systems |= (. + {revision: $revision, url: $url, sha256: $sha256})' pins.json > pins.json.tmp
mv pins.json.tmp pins.json
