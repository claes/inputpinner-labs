#!/usr/bin/env bash
# Builds consume shipped locks. Optional update checks use disposable copies.
set -euo pipefail
cd -- "$(dirname -- "$0")"
root=$PWD
approaches=(flake niv npins lon nixtamal tack mana manual)
if [[ ${1:-} == --syntax-only && $# == 1 ]]; then
  for approach in "${approaches[@]}"; do
    while IFS= read -r -d '' expression; do
      nix-instantiate --parse "$expression" > /dev/null
    done < <(find "$approach/04-selective-updates" -type f -name '*.nix' -print0)
    bash -n "$approach/04-selective-updates/init.sh"
    bash -n "$approach/04-selective-updates/update.sh"
  done
  bash -n "$0"
  printf '%s\n' 'Example 04 Nix and Bash syntax checks passed.'
  exit 0
fi
[[ $# == 0 || ( $# == 1 && $1 == --updates ) ]] || {
  printf '%s\n' 'Usage: ./verify-04.sh [--syntax-only | --updates]' >&2; exit 2;
}
system=$(nix eval --impure --raw --expr builtins.currentSystem)
[[ $system == x86_64-linux ]] || { printf 'This check targets x86_64-linux; got %s.\n' "$system" >&2; exit 2; }

# Normalize only for comparison; keep each tool's native lock format on disk.
lock_entry() {
  case "$1" in
    flake) jq -cS --arg n "$3" '.nodes[$n]' "$2/flake.lock" ;;
    niv) jq -cS --arg n "$3" '.[$n]' "$2/nix/sources.json" ;;
    npins) jq -cS --arg n "$3" '.pins[$n]' "$2/npins/sources.json" ;;
    lon) jq -cS --arg n "$3" '.sources[$n]' "$2/lon.lock" ;;
    nixtamal) jq -cS --arg n "$3" '.i[$n]' "$2/nix/tamal/lock.json" ;;
    tack) jq -cS --arg n "$3" '.[$n]' "$2/.tack/pins.lock.json" ;;
    mana) jq -cS --arg n "/$3" '.sources[$n]' "$2/lock.json" ;;
    manual) jq -cS --arg n "$3" '.[$n]' "$2/pins.json" ;;
  esac
}
revision() {
  lock_entry "$@" | jq -r '.locked.rev // .rev // .revision // .fv'
}
tracks_unstable() {
  case "$1" in
    flake) jq -e '.nodes.unstable.original.ref == "nixpkgs-unstable"' "$2/flake.lock" > /dev/null ;;
    niv) jq -e '.unstable.branch == "nixpkgs-unstable"' "$2/nix/sources.json" > /dev/null ;;
    npins) jq -e '.pins.unstable.branch == "nixpkgs-unstable"' "$2/npins/sources.json" > /dev/null ;;
    lon) jq -e '.sources.unstable.branch == "nixpkgs-unstable"' "$2/lon.lock" > /dev/null ;;
    nixtamal) grep -Fq '"refs/heads/nixpkgs-unstable"' "$2/nix/tamal/manifest.kdl" ;;
    tack) grep -Fq 'url = "github:NixOS/nixpkgs/nixpkgs-unstable"' "$2/.tack/pins.toml" ;;
    mana) [[ $(nix eval --raw --file "$2/mana.nix" dependencies.unstable.url) == github:NixOS/nixpkgs/nixpkgs-unstable ]] ;;
    manual) jq -e '.unstable.branch == "nixpkgs-unstable"' "$2/pins.json" > /dev/null ;;
  esac
}
fingerprint() {
  find "$1" -type f -exec sha256sum {} + | LC_ALL=C sort | sha256sum
}
build_pair() {
  local approach=$1 example=$2 pin
  local before
  before=$(fingerprint "$example")
  for pin in stable unstable; do
    if [[ $approach == flake ]]; then
      (cd "$example" && nix build "path:.#$pin" --out-link "result-$pin")
    else
      (cd "$example" && nix-build -A "$pin" -o "result-$pin")
    fi
    [[ $("$example/result-$pin/bin/hello") == 'Hello, world!' ]]
    "$example/result-$pin/bin/hello" --version | head -1
  done
  [[ $(fingerprint "$example") == "$before" ]] || { printf 'Build changed files: %s\n' "$approach" >&2; exit 1; }
}
drv() {
  if [[ $1 == flake ]]; then
    (cd "$2" && nix eval --raw "path:.#packages.x86_64-linux.$3.drvPath")
  else
    (cd "$2" && nix eval --impure --raw --expr "(import ./. {}).$3.drvPath")
  fi
}
stable_seed=$(cat manual/04-selective-updates/stable-revision)
unstable_seed=$(cat manual/04-selective-updates/unstable-revision)
stable_drv=''
unstable_drv=''
for approach in "${approaches[@]}"; do
  example="$root/$approach/04-selective-updates"
  [[ $(cat "$example/stable-revision") == "$stable_seed" &&
     $(cat "$example/unstable-revision") == "$unstable_seed" &&
     $(revision "$approach" "$example" stable) == "$stable_seed" &&
     $(revision "$approach" "$example" unstable) == "$unstable_seed" ]]
  tracks_unstable "$approach" "$example"
  build_pair "$approach" "$example"
  current_stable=$(drv "$approach" "$example" stable)
  current_unstable=$(drv "$approach" "$example" unstable)
  if [[ -z $stable_drv ]]; then stable_drv=$current_stable; unstable_drv=$current_unstable; fi
  [[ $current_stable == "$stable_drv" && $current_unstable == "$unstable_drv" ]]
  printf '%s: both initial locks, matching Hello derivations, and unchanged files verified\n' "$approach"
done
[[ $stable_drv != "$unstable_drv" ]]

if [[ ${1:-} == --updates ]]; then
  # Require maintenance CLIs only for the explicitly requested update exercise.
  for command in niv npins lon nixtamal tack git; do command -v "$command" > /dev/null; done
  scratch=$(mktemp -d "${TMPDIR:-/tmp}/inputpinner-04.XXXXXXXX")
  trap 'rm -rf -- "$scratch"' EXIT
  updated_drv=''
  for approach in "${approaches[@]}"; do
    example="$scratch/$approach/lab with spaces"
    mkdir -p "$(dirname -- "$example")"
    cp -a "$root/$approach/04-selective-updates" "$example"
    before_stable=$(lock_entry "$approach" "$example" stable)
    (cd "$example" && ./update.sh)
    [[ $(lock_entry "$approach" "$example" stable) == "$before_stable" ]]
    updated_revision=$(revision "$approach" "$example" unstable)
    [[ $updated_revision =~ ^[0-9a-f]{40}$ && $updated_revision != "$unstable_seed" ]]
    build_pair "$approach" "$example"
    [[ $(drv "$approach" "$example" stable) == "$stable_drv" ]]
    current_unstable=$(drv "$approach" "$example" unstable)
    [[ $current_unstable != "$unstable_drv" ]]
    if [[ -z $updated_drv ]]; then updated_drv=$current_unstable; fi
    # A moving branch can advance between tools; compare builds at equal commits.
    if [[ $approach == flake ]]; then first_revision=$updated_revision; fi
    if [[ $updated_revision == "$first_revision" ]]; then [[ $current_unstable == "$updated_drv" ]]; fi
    printf '%s: unstable advanced to %s; stable lock and derivation unchanged\n' "$approach" "$updated_revision"
  done
fi
