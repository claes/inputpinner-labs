#!/usr/bin/env bash
# Verify the shipped historical snapshot; exercise updates in disposable copies.
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ ${1:-} == --syntax-only && $# == 1 ]]; then
  for approach in flake niv npins lon nixtamal tack mana manual; do
    while IFS= read -r -d '' expression; do
      nix-instantiate --parse "$expression" > /dev/null
    done < <(find "$approach/03-git-branch" -type f -name '*.nix' -print0)
    bash -n "$approach/03-git-branch/init.sh"
    bash -n "$approach/03-git-branch/update.sh"
  done
  bash -n "$0"
  printf '%s\n' 'Example 03 Nix and Bash syntax checks passed.'
  exit 0
fi
if [[ $# != 0 ]]; then
  printf '%s\n' 'Usage: ./verify-03.sh [--syntax-only]' >&2
  exit 2
fi

system=$(nix eval --impure --raw --expr builtins.currentSystem)
[[ $system == x86_64-linux ]] || { printf 'This check targets x86_64-linux; got %s.\n' "$system" >&2; exit 2; }

locked_revisions() {
  case "$1" in
    flake) jq -r '[.nodes.nixpkgs.locked.rev, .nodes.systems.locked.rev][]' "$2/flake.lock" ;;
    niv) jq -r '[.nixpkgs.rev, .systems.rev][]' "$2/nix/sources.json" ;;
    npins) jq -r '[.pins.nixpkgs.revision, .pins.systems.revision][]' "$2/npins/sources.json" ;;
    lon) jq -r '[.sources.nixpkgs.revision, .sources.systems.revision][]' "$2/lon.lock" ;;
    nixtamal) jq -r '[.i.nixpkgs.fv, .i.systems.fv][]' "$2/nix/tamal/lock.json" ;;
    tack) jq -r '[.nixpkgs.rev, .systems.rev][]' "$2/.tack/pins.lock.json" ;;
    mana) jq -r '[.sources["/nixpkgs"].locked.rev, .sources["/systems"].locked.rev][]' "$2/lock.json" ;;
    manual) jq -r '[.nixpkgs.revision, .systems.revision][]' "$2/pins.json" ;;
  esac
}

tracks_main() {
  case "$1" in
    flake) jq -e '.nodes.systems.original.ref == "main"' "$2/flake.lock" > /dev/null ;;
    niv) jq -e '.systems.branch == "main"' "$2/nix/sources.json" > /dev/null ;;
    npins) jq -e '.pins.systems.branch == "main"' "$2/npins/sources.json" > /dev/null ;;
    lon) jq -e '.sources.systems.branch == "main"' "$2/lon.lock" > /dev/null ;;
    nixtamal) grep -Fq '"refs/heads/main"' "$2/nix/tamal/manifest.kdl" ;;
    tack) grep -Fq 'url = "github:nix-systems/default/main"' "$2/.tack/pins.toml" ;;
    mana) [[ $(nix eval --raw --file "$2/mana.nix" dependencies.systems.url) == github:nix-systems/default/main ]] ;;
    manual) jq -e '.systems.branch == "main"' "$2/pins.json" > /dev/null ;;
  esac
}

source_expression() {
  case "$1" in
    flake) printf '%s' 'let lock = builtins.fromJSON (builtins.readFile ./flake.lock); in builtins.fetchTree lock.nodes.systems.locked' ;;
    niv) printf '%s' '(import ./nix/sources.nix {}).systems' ;;
    npins) printf '%s' '(import ./npins).systems' ;;
    lon) printf '%s' '(import ./lon.nix).systems' ;;
    nixtamal) printf '%s' '(import ./nix/tamal {}).systems' ;;
    tack) printf '%s' '(import ./.tack).systems' ;;
    mana) printf '%s' 'let lock = builtins.fromJSON (builtins.readFile ./lock.json); pin = lock.sources."/systems"; in builtins.fetchTree (builtins.removeAttrs pin.args [ "ref" ] // builtins.removeAttrs pin.locked [ "lastModified" "lastModifiedDate" "shortRev" ])' ;;
    manual) printf '%s' 'let pins = builtins.fromJSON (builtins.readFile ./pins.json); in builtins.fetchTarball { inherit (pins.systems) url sha256; }' ;;
  esac
}

fingerprint() {
  find "$1" -type f -exec sha256sum {} + | LC_ALL=C sort | sha256sum
}

expected_revision=$(cat manual/03-git-branch/revision)
expected_systems_revision=$(cat manual/03-git-branch/systems-revision)
expected_revisions=$(printf '%s\n%s' "$expected_revision" "$expected_systems_revision")
expected_hash=$(nix hash convert --hash-algo sha256 --to sri "$(jq -r .systems.sha256 manual/03-git-branch/pins.json)")
expected_text=$(printf '%s\n' aarch64-darwin aarch64-linux x86_64-darwin x86_64-linux)
baseline=''

for approach in flake niv npins lon nixtamal tack mana manual; do
  example="$approach/03-git-branch"
  [[ $(cat "$example/revision") == "$expected_revision" &&
     $(cat "$example/systems-revision") == "$expected_systems_revision" &&
     $(locked_revisions "$approach" "$example") == "$expected_revisions" ]] || {
    printf 'Initial revisions differ: %s\n' "$approach" >&2; exit 1;
  }
  tracks_main "$approach" "$example" || { printf 'Update target is not main: %s\n' "$approach" >&2; exit 1; }
  before=$(fingerprint "$example")
  if [[ $approach == flake ]]; then
    (cd "$example" && nix build path:.)
    drv=$(cd "$example" && nix eval --raw 'path:.#packages.x86_64-linux.default.drvPath')
  elif [[ $approach == mana ]]; then
    (cd "$example" && nix-build -A systems)
    drv=$(cd "$example" && nix eval --impure --raw --expr '(import ./. {}).systems.drvPath')
  else
    (cd "$example" && nix-build)
    drv=$(cd "$example" && nix eval --impure --raw --expr '(import ./. {}).drvPath')
  fi
  expr=$(source_expression "$approach")
  source=$(cd "$example" && nix eval --impure --raw --expr "builtins.toString ($expr)")
  [[ $(nix hash path "$source") == "$expected_hash" ]] || { printf 'Pinned source differs: %s\n' "$approach" >&2; exit 1; }
  resolved_text=$(cd "$example" && nix eval --impure --json --expr "import ($expr)" | jq -r '.[]')
  [[ $resolved_text == "$expected_text" ]] || { printf 'Initial systems list differs: %s\n' "$approach" >&2; exit 1; }
  cmp "$example/result" <(printf '%s\n' "$resolved_text")
  [[ $(fingerprint "$example") == "$before" ]] || { printf 'Build changed example files: %s\n' "$approach" >&2; exit 1; }
  if [[ -z $baseline ]]; then baseline=$drv; fi
  [[ $drv == "$baseline" ]] || { printf 'Text derivation differs: %s\n' "$approach" >&2; exit 1; }
  printf '%s: locked snapshot, main target, source, text, and unchanged files verified\n' "$approach"
done
