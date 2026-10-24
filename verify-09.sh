#!/usr/bin/env bash
# Consume shipped pins, then optionally test source updates and patch repair in copies.
set -euo pipefail
cd -- "$(dirname -- "$0")"
root=$PWD
approaches=(flake niv npins lon nixtamal tack mana manual)
if [[ ${1:-} == --syntax-only && $# == 1 ]]; then
  for approach in "${approaches[@]}"; do
    while IFS= read -r -d '' expression; do
      nix-instantiate --parse "$expression" > /dev/null
    done < <(find "$approach/09-patches" -type f -name '*.nix' -print0)
    bash -n "$approach/09-patches/init.sh"
    bash -n "$approach/09-patches/update.sh"
  done
  bash -n "$0"
  printf '%s\n' 'Example 09 Nix and Bash syntax checks passed.'
  exit 0
fi
[[ $# == 0 || ( $# == 1 && $1 == --updates ) ]] || {
  printf '%s\n' 'Usage: ./verify-09.sh [--syntax-only | --updates]' >&2; exit 2;
}
system=$(nix eval --impure --raw --expr builtins.currentSystem)
[[ $system == x86_64-linux ]] || { printf 'This check targets x86_64-linux; got %s.\n' "$system" >&2; exit 2; }
unset NIV_OVERRIDE_nixpkgs NIV_OVERRIDE_systems NPINS_OVERRIDE_nixpkgs NPINS_OVERRIDE_systems
unset LON_OVERRIDE_nixpkgs LON_OVERRIDE_systems
if [[ ${1:-} == --updates ]]; then
  for command in niv npins lon nixtamal tack; do command -v "$command" > /dev/null; done
fi
scratch=$(mktemp -d "${TMPDIR:-/tmp}/inputpinner-09.XXXXXXXX")
trap 'rm -rf -- "$scratch"' EXIT
cat > "$scratch/expected.nix" <<'NIX'
[
  "aarch64-darwin"
  "aarch64-linux"
  "riscv64-linux"
  "x86_64-linux"
]
NIX
# Native records remain on disk; canonicalize only for comparisons.
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
revision() { lock_entry "$@" | jq -r '.locked.rev // .rev // .revision // .fv'; }
fingerprint() { find "$1" -type f -exec sha256sum {} + | LC_ALL=C sort | sha256sum; }
drv() {
  case "$1" in
    flake) (cd "$2" && nix eval --raw path:.#packages.x86_64-linux.default.drvPath) ;;
    mana) (cd "$2" && nix eval --impure --raw --expr '(import ./. {}).systems.drvPath') ;;
    *) (cd "$2" && nix eval --impure --raw --expr '(import ./. {}).drvPath') ;;
  esac
}
build() {
  case "$1" in
    flake) (cd "$2" && nix build path:. --out-link "$3") ;;
    mana) (cd "$2" && nix-build -A systems -o "$3") ;;
    *) (cd "$2" && nix-build -o "$3") ;;
  esac
}
check_output() {
  cmp "$1" "$scratch/expected.nix"
  [[ $(nix eval --json --file "$1") == '["aarch64-darwin","aarch64-linux","riscv64-linux","x86_64-linux"]' ]]
  [[ $(nix hash path "$(readlink -f -- "$1")") == "$expected_output_hash" ]]
}
seed=$(cat manual/09-patches/systems-revision)
target=$(cat manual/09-patches/updated-systems-revision)
parent=$(cat manual/09-patches/revision)
expected_source_hash='sha256-Vy1rq5AaRuLzOxct8nz4T6wlgyUR7zLU309k9mBC768='
updated_source_hash='sha256-uuanbkFk8a313Zfrxdcz8Us/yQtaxNnKJtX8v0ZPpd8='
expected_output_hash=$(nix hash path "$scratch/expected.nix")
declare -A initial_drvs repaired_drvs
for approach in "${approaches[@]}"; do
  example="$scratch/lab with spaces/$approach/09-patches"
  mkdir -p "$example"
  tar -C "$root/$approach/09-patches" --exclude='./result*' --exclude='*.tmp' \
    --exclude=./next_lock.json -cf - . | tar -C "$example" -xf -
  [[ $(cat "$example/systems-revision") == "$seed" &&
     $(cat "$example/updated-systems-revision") == "$target" &&
     $(revision "$approach" "$example" systems) == "$seed" &&
     $(revision "$approach" "$example" nixpkgs) == "$parent" ]]
  cmp "$example/local.patch" "$root/manual/09-patches/local.patch"
  cmp "$example/local.after-update.patch" "$root/manual/09-patches/local.after-update.patch"
  before=$(fingerprint "$example")
  initial_drv=$(drv "$approach" "$example")
  source=$(nix-store --query --binding src "$initial_drv")
  [[ $(nix hash path "$source") == "$expected_source_hash" ]]
  # Compare derivations only when native source paths match (names are meaningful).
  if [[ -v initial_drvs[$source] ]]; then
    [[ ${initial_drvs[$source]} == "$initial_drv" ]]
  else
    initial_drvs[$source]=$initial_drv
  fi
  build "$approach" "$example" result
  check_output "$example/result"
  [[ $(fingerprint "$example") == "$before" && $(nix hash path "$source") == "$expected_source_hash" ]]
  printf '%s: initial patch, original source hash, output contents and unchanged files verified\n' "$approach"
  if [[ ${1:-} != --updates ]]; then continue; fi

  parent_before=$(lock_entry "$approach" "$example" nixpkgs)
  # The pinned Mana maintenance CLI cannot quote a cwd containing spaces.
  # Move only while updating; both consumption builds still use the spaced path.
  if [[ $approach == mana ]]; then
    mv "$example" "$scratch/mana-maintenance"
    (cd "$scratch/mana-maintenance" && ./update.sh)
    mv "$scratch/mana-maintenance" "$example"
  else
    (cd "$example" && ./update.sh)
  fi
  [[ $(revision "$approach" "$example" systems) == "$target" &&
     $(lock_entry "$approach" "$example" nixpkgs) == "$parent_before" &&
     $(cat "$example/systems-revision") == "$seed" ]]
  cmp "$example/local.patch" "$root/manual/09-patches/local.patch"
  updated_drv=$(drv "$approach" "$example")
  updated_source=$(nix-store --query --binding src "$updated_drv")
  [[ $updated_drv != "$initial_drv" && $(nix hash path "$updated_source") == "$updated_source_hash" ]]
  before=$(fingerprint "$example")
  if build "$approach" "$example" result-updated > "$scratch/$approach-failure.log" 2>&1; then
    printf 'Expected a stale patch failure: %s\n' "$approach" >&2; exit 1
  fi
  # Require a patch-hunk rejection, rather than accepting any failed build.
  nix-store --read-log "$updated_drv" > "$scratch/$approach-patch.log"
  grep -Eq 'Hunk #1 FAILED|1 out of 1 hunk FAILED' "$scratch/$approach-patch.log"
  [[ ! -e $example/result-updated && ! -L $example/result-updated && $(fingerprint "$example") == "$before" ]]

  # This explicit, reviewed consumer change repairs the patch, not the source pin.
  cp "$example/local.after-update.patch" "$example/local.patch"
  before=$(fingerprint "$example")
  repaired_drv=$(drv "$approach" "$example")
  [[ $repaired_drv != "$updated_drv" && $repaired_drv != "$initial_drv" ]]
  [[ $(nix-store --query --binding src "$repaired_drv") == "$updated_source" ]]
  if [[ -v repaired_drvs[$updated_source] ]]; then
    [[ ${repaired_drvs[$updated_source]} == "$repaired_drv" ]]
  else
    repaired_drvs[$updated_source]=$repaired_drv
  fi
  build "$approach" "$example" result-repaired
  check_output "$example/result-repaired"
  [[ $(fingerprint "$example") == "$before" &&
     $(lock_entry "$approach" "$example" nixpkgs) == "$parent_before" &&
     $(nix hash path "$source") == "$expected_source_hash" &&
     $(nix hash path "$updated_source") == "$updated_source_hash" ]]
  printf '%s: fixed source update, patch-hunk failure, explicit repair and retained parent pin verified\n' "$approach"
done
printf 'Example 09 passed across all eight approaches (%s native source-path groups).\n' "${#initial_drvs[@]}"
