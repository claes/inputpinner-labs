#!/usr/bin/env bash
set -euo pipefail

# Resolve the project directory even when launched from another working directory.
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

# Downloads run inside the sandbox. If Nix's daemon socket is blocked, Codex can
# request permission to run that command outside the sandbox.
exec codex \
  --cd "$project_dir" \
  --sandbox workspace-write \
  --ask-for-approval on-request \
  --config 'approvals_reviewer="user"' \
  --config sandbox_workspace_write.network_access=true \
  "$@"
