#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Initialization is maintenance; building uses the shipped files directly.
if [[ -e npins/sources.json ]]; then
  printf '%s\n' 'Already initialized; use a disposable copy for experiments.' >&2
  exit 1
fi
scratch=$(mktemp -d "${TMPDIR:-/tmp}/unflake-init.XXXXXXXX")
trap 'rm -rf -- "$scratch"' EXIT
cp inputs.nix revision patchelf-revision "$scratch/"
tool_ref=$(cat unflake-tool-ref)
nix --version > versions.txt
printf 'unflake source: %s\n' "$tool_ref" >> versions.txt
npins --version >> versions.txt
# npins is unflake's supported source backend. Other pinners replace this backend
# below; they retain the generated dependency injection code without forking it.
(cd "$scratch" && npins init --bare && nix run -f "$tool_ref" unflake -- -b npins -j 1)
cp "$scratch/unflake.nix" unflake.nix
# Give generated IDs short local names, keeping two nixpkgs pins only in 06/07.
jq --arg parent "$(cat revision)" '
  .pins | to_entries | map({
    key: (if .value.repository.repo == "nixpkgs" then
      (if .value.revision == $parent then "nixpkgs" else "upstream-nixpkgs" end)
      elif .value.repository.repo == "patchelf" then "patchelf"
      elif .value.repository.repo == "flake-parts" then "flake-parts"
      elif .value.repository.repo == "git-hooks.nix" then "git-hooks-nix"
      elif .value.repository.repo == "gitignore.nix" then "gitignore"
      elif .value.repository.repo == "flake-compat" then "upstream-flake-compat"
      else error("Unexpected dependency: " + .key) end), value: .key
  }) | from_entries' "$scratch/npins/sources.json" > source-map.json
# Keep the supported npins backend and its generated pin names unchanged.
cp -R "$scratch/npins" .

