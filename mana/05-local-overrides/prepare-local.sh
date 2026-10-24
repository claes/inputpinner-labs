#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Keep an existing checkout and its edits safe: initialization is explicit.
if [[ -e local-systems || -L local-systems ]]; then
  printf '%s\n' 'local-systems already exists; keep it or move it aside first.' >&2
  exit 1
fi
revision=$(cat systems-revision)
# Check out the same commit as the remote lock, independently of today's main.
git clone --quiet --no-checkout https://github.com/nix-systems/default.git local-systems
git -C local-systems checkout --quiet --detach "$revision"
# This is data consumed by writeText; adding a target does not cross-compile it.
cat > local-systems/default.nix <<'NIX'
# Local development edit: add one system to the pinned upstream list.
[
  "aarch64-darwin"
  "aarch64-linux"
  "x86_64-darwin"
  "x86_64-linux"
  "riscv64-linux"
]
NIX
printf '%s\n' 'Prepared an editable local checkout; run ./build-local.sh.'
