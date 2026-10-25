#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

# Initialization is maintenance; building uses the shipped files directly.
if [[ -e nix/tamal/manifest.kdl ]]; then
  printf '%s\n' 'Already initialized; use a disposable copy for experiments.' >&2
  exit 1
fi
# Generate with the supported backend in isolation; builds use Nixtamal's shipped pins.
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
# A short alias must identify each dependency once; reject accidental collisions.
[[ $(jq 'length' source-map.json) == $(jq '.pins | length' "$scratch/npins/sources.json") ]]
nixtamal --version >> versions.txt
nixtamal set-up --no-nixpkgs --fetch-time=eval --hash-algorithm=SHA-256
printf 'version "1.1.0"\ninputs {\n' > nix/tamal/manifest.kdl
# Import the resolved graph into this pinner, not into a second fetching backend.
while IFS=$'\t' read -r name owner repo revision _branch _url _hash; do
  if [[ $owner == nixos ]]; then owner=NixOS; fi
  cat >> nix/tamal/manifest.kdl <<EOF
    $name {
        archive fetch-time=eval {
            url "https://github.com/$owner/$repo/archive/{{fresh_value}}.tar.gz"
        }
        hash algorithm=SHA-256
        fresh-cmd {
            \$ echo "$revision"
        }
    }
EOF
done < <(jq -r --slurpfile names source-map.json '
  .pins | to_entries[] | . as $pin |
  ($names[0] | to_entries[] | select(.value == $pin.key) | .key) as $name |
  [$name, .value.repository.owner, .value.repository.repo, .value.revision,
   .value.branch, .value.url, .value.hash] | @tsv' "$scratch/npins/sources.json")
printf '}\n' >> nix/tamal/manifest.kdl
nixtamal lock --no-tui
# Only replace the supported backend import; fail if unflake changes its format.
[[ $(grep -Fc '(import ./npins/default.nix)' unflake.nix) == 1 ]]
sed -i 's@(import ./npins/default.nix)@(import ./unflake-sources.nix)@' unflake.nix

