#!/usr/bin/env bash
# Exercise edits in disposable copies, preserving any developer checkouts.
set -euo pipefail
cd -- "$(dirname -- "$0")"
root=$PWD
approaches=(flake niv npins lon nixtamal tack mana manual)
if [[ ${1:-} == --syntax-only && $# == 1 ]]; then
  for approach in "${approaches[@]}"; do
    while IFS= read -r -d '' expression; do
      nix-instantiate --parse "$expression" > /dev/null
    done < <(find "$approach/05-local-overrides" -type f -name '*.nix' ! -path '*/local-systems/*' -print0)
    bash -n "$approach/05-local-overrides/init.sh"
    bash -n "$approach/05-local-overrides/prepare-local.sh"
    bash -n "$approach/05-local-overrides/build-local.sh"
  done
  bash -n "$0"
  printf '%s\n' 'Example 05 Nix and Bash syntax checks passed.'
  exit 0
fi
[[ $# == 0 ]] || { printf '%s\n' 'Usage: ./verify-05.sh [--syntax-only]' >&2; exit 2; }
system=$(nix eval --impure --raw --expr builtins.currentSystem)
[[ $system == x86_64-linux ]] || { printf 'This check targets x86_64-linux; got %s.\n' "$system" >&2; exit 2; }
# Prevent an inherited development override from affecting the remote baseline.
unset NIV_OVERRIDE_systems NPINS_OVERRIDE_systems LON_OVERRIDE_systems
scratch_base=$(mktemp -d "${TMPDIR:-/tmp}/inputpinner-05.XXXXXXXX")
trap 'rm -rf -- "$scratch_base"' EXIT
scratch="$scratch_base/lab with spaces"
mkdir -p "$scratch"
cp "$root/clean.sh" "$scratch/clean.sh"

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
fingerprint() {
  find "$1" -type f ! -path "$1/local-systems/*" -exec sha256sum {} + | LC_ALL=C sort | sha256sum
}
checkout_fingerprint() {
  find "$1" -type f -exec sha256sum {} + | LC_ALL=C sort | sha256sum
}
build_remote() {
  if [[ $1 == flake ]]; then
    (cd "$2" && nix build path:.)
  elif [[ $1 == mana ]]; then
    (cd "$2" && nix-build -A systems)
  else
    (cd "$2" && nix-build)
  fi
}
# Read the actual build result's derivation, including overrides used by scripts.
result_drv() { nix-store --query --deriver "$1"; }
expected_remote=$(printf '%s\n' aarch64-darwin aarch64-linux x86_64-darwin x86_64-linux)
expected_local=$(printf '%s\nriscv64-linux' "$expected_remote")
expected_edited=$(printf '%s\npowerpc64le-linux' "$expected_local")
revision=$(cat manual/05-local-overrides/revision)
systems_revision=$(cat manual/05-local-overrides/systems-revision)
expected_revisions=$(printf '%s\n%s' "$revision" "$systems_revision")
baseline_drv=''
local_drv=''
edited_drv=''

for approach in "${approaches[@]}"; do
  example="$scratch/$approach/05-local-overrides"
  mkdir -p "$example"
  # Copy generated locks/resolvers but never a user's checkout or artifacts.
  tar -C "$root/$approach/05-local-overrides" \
    --exclude=./local-systems --exclude='./result*' --exclude='*.tmp' \
    --exclude=./next_lock.json -cf - . | tar -C "$example" -xf -
  before=$(fingerprint "$example")
  [[ $(cat "$example/revision") == "$revision" &&
     $(cat "$example/systems-revision") == "$systems_revision" &&
     $(locked_revisions "$approach" "$example") == "$expected_revisions" ]]
  build_remote "$approach" "$example"
  cmp "$example/result" <(printf '%s\n' "$expected_remote")
  current_baseline=$(result_drv "$example/result")
  if [[ -z $baseline_drv ]]; then baseline_drv=$current_baseline; fi
  [[ $current_baseline == "$baseline_drv" ]]

  (cd "$example" && ./prepare-local.sh)
  checkout="$example/local-systems"
  [[ $(git -C "$checkout" rev-parse HEAD) == "$systems_revision" ]]
  [[ $(git -C "$checkout" diff --name-only) == default.nix ]]
  checkout_before=$(checkout_fingerprint "$checkout")
  # Refuse to overwrite an existing checkout, including its local edits.
  if (cd "$example" && ./prepare-local.sh > "$scratch/prepare-again.log" 2>&1); then
    printf 'Preparation overwrote an existing checkout: %s\n' "$approach" >&2; exit 1
  fi
  [[ $(checkout_fingerprint "$checkout") == "$checkout_before" ]]
  (cd "$example" && ./build-local.sh)
  cmp "$example/result-local" <(printf '%s\n' "$expected_local")
  current_local=$(result_drv "$example/result-local")
  if [[ -z $local_drv ]]; then local_drv=$current_local; fi
  [[ $current_local == "$local_drv" && $current_local != "$baseline_drv" ]]
  [[ $(checkout_fingerprint "$checkout") == "$checkout_before" ]]
  [[ $(fingerprint "$example") == "$before" ]]

  # A second uncommitted edit must be read on the next local build.
  sed -i '/^]/i\  "powerpc64le-linux"' "$checkout/default.nix"
  checkout_before=$(checkout_fingerprint "$checkout")
  # Pass the path explicitly too, exercising an argument containing spaces.
  (cd "$example" && ./build-local.sh "$checkout")
  cmp "$example/result-local" <(printf '%s\n' "$expected_edited")
  current_edited=$(result_drv "$example/result-local")
  if [[ -z $edited_drv ]]; then edited_drv=$current_edited; fi
  [[ $current_edited == "$edited_drv" && $current_edited != "$local_drv" ]]

  # Omitting the override restores the remote pin while the checkout still exists.
  build_remote "$approach" "$example"
  cmp "$example/result" <(printf '%s\n' "$expected_remote")
  [[ $(result_drv "$example/result") == "$baseline_drv" ]]
  [[ $(checkout_fingerprint "$checkout") == "$checkout_before" ]]
  [[ $(fingerprint "$example") == "$before" ]]

  # Check cleanup against editable source that happens to look like an artifact.
  printf '%s\n' 'keep this local edit' > "$checkout/keep.tmp"
  ln -s default.nix "$checkout/result"
  printf '%s\n' 'disposable' > "$example/cleanup-test.tmp"
  (cd "$scratch" && ./clean.sh > cleanup.log)
  [[ -f "$checkout/keep.tmp" && -L "$checkout/result" ]]
  [[ ! -L "$example/result" && ! -L "$example/result-local" ]]
  [[ $(fingerprint "$example") == "$before" ]]
  printf '%s: remote, two local edits, restored pin, unchanged locks, and checkout-safe cleanup verified\n' "$approach"
done
