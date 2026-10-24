#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Name the input explicitly: updating everything would also advance stable.
nix run "$(cat tool-ref)" -- update unstable
