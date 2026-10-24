#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Refresh the tracked systems branch; a normal build never changes its lock.
niv update systems
