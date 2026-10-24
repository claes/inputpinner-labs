#!/usr/bin/env bash
# Consume the shipped pins in fresh copies; never initialize or update them.
set -eEuo pipefail
trap 'printf "Example 06 failed at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR
cd -- "$(dirname -- "$0")"
root=$PWD
approaches=(flake niv npins lon nixtamal tack mana manual)
examples=()
for approach in "${approaches[@]}"; do
  if [[ $approach == flake || $approach == tack ]]; then
    examples+=("$approach/06-flake-package")
  else
    for library in flake-compat flake-inputs; do
      examples+=("$approach/06-flake-package-$library")
    done
  fi
done
[[ ${#examples[@]} == 14 ]]
if [[ ${1:-} == --syntax-only && $# == 1 ]]; then
  for relative in "${examples[@]}"; do
    while IFS= read -r -d '' expression; do
      nix-instantiate --parse "$expression" > /dev/null
    done < <(find "$relative" -type f -name '*.nix' -print0)
    bash -n "$relative/init.sh"
  done
  bash -n "$0"
  ./verify-unflake.sh 06 --syntax-only
  ./verify-with-inputs.sh 06 --syntax-only
  printf '%s\n' 'Example 06 Nix and Bash syntax checks passed.'
  exit 0
fi
[[ $# == 0 ]] || { printf '%s\n' 'Usage: ./verify-06.sh [--syntax-only]' >&2; exit 2; }
export NIX_CONFIG="${NIX_CONFIG:-}
allow-import-from-derivation = false"
system=$(nix eval --impure --raw --expr builtins.currentSystem)
[[ $system == x86_64-linux ]] || { printf 'This check targets x86_64-linux; got %s.\n' "$system" >&2; exit 2; }
# Development overrides must not replace the comparison's shipped sources.
unset NIV_OVERRIDE_nixpkgs NIV_OVERRIDE_patchelf
unset NPINS_OVERRIDE_nixpkgs NPINS_OVERRIDE_patchelf
unset LON_OVERRIDE_nixpkgs LON_OVERRIDE_patchelf
# Hyphenated input names are sanitized by niv/npins and preserved by Lon.
unset NIV_OVERRIDE_flake_compat NPINS_OVERRIDE_flake_compat NIV_OVERRIDE_flake_inputs NPINS_OVERRIDE_flake_inputs

scratch_base=$(mktemp -d "${TMPDIR:-/tmp}/inputpinner-06.XXXXXXXX")
trap 'rm -rf -- "$scratch_base"' EXIT
scratch="$scratch_base/lab with spaces"
mkdir -p "$scratch"

# Normalize only the revisions for comparison; retain native lock representations.
locked_revision() {
  case "$1" in
    flake) jq -r --arg n "$3" '.nodes[$n].locked.rev' "$2/flake.lock" ;;
    niv) jq -r --arg n "$3" '.[$n].rev' "$2/nix/sources.json" ;;
    npins) jq -r --arg n "$3" '.pins[$n].revision' "$2/npins/sources.json" ;;
    lon) jq -r --arg n "$3" '.sources[$n].revision' "$2/lon.lock" ;;
    nixtamal) jq -r --arg n "$3" '.i[$n].fv' "$2/nix/tamal/lock.json" ;;
    tack) jq -r --arg n "$3" '.[$n].rev' "$2/.tack/pins.lock.json" ;;
    mana) jq -r --arg n "/$3" '.sources[$n].locked.rev' "$2/lock.json" ;;
    manual) jq -r --arg n "$3" '.[$n].revision' "$2/pins.json" ;;
  esac
}
source_expression() {
  case "$1" in
    flake) printf 'let lock = builtins.fromJSON (builtins.readFile ./flake.lock); in builtins.fetchTree lock.nodes."%s".locked' "$2" ;;
    niv) printf '(import ./nix/sources.nix {})."%s"' "$2" ;;
    npins) printf '(import ./npins)."%s"' "$2" ;;
    lon) printf '(import ./lon.nix)."%s"' "$2" ;;
    nixtamal) printf '(import ./nix/tamal {})."%s"' "$2" ;;
    tack) printf '(import ./.tack)."%s"' "$2" ;;
    mana) printf 'let lock = builtins.fromJSON (builtins.readFile ./lock.json); pin = lock.sources."/%s"; in builtins.fetchTree (builtins.removeAttrs pin.args [ "ref" ] // builtins.removeAttrs pin.locked [ "lastModified" "lastModifiedDate" "shortRev" ])' "$2" ;;
    manual) printf 'let pins = builtins.fromJSON (builtins.readFile ./pins.json); in builtins.fetchTarball { inherit (pins."%s") url sha256; }' "$2" ;;
  esac
}
fingerprint() {
  find "$1" -type f -exec sha256sum {} + | LC_ALL=C sort | sha256sum
}
# Store paths are immutable; hash each distinct tree only once per verification.
declare -A source_hashes
check_hash() {
  local path=$1 expected=$2
  [[ $path == /nix/store/* ]]
  if [[ ! -v source_hashes[$path] ]]; then source_hashes[$path]=$(nix hash path "$path"); fi
  [[ ${source_hashes[$path]} == "$expected" ]]
}
revision=$(cat "$root/manual/06-flake-package-flake-compat/revision")
patchelf_revision=$(cat "$root/manual/06-flake-package-flake-compat/patchelf-revision")


# Independent reference: evaluate and build the original upstream output directly.
upstream_ref="github:NixOS/patchelf/$patchelf_revision"
upstream_drv=$(nix eval --raw "$upstream_ref#packages.$system.default.drvPath")
upstream_output=$(nix build "$upstream_ref#packages.$system.default" --no-link --print-out-paths)
expected_version=$("$upstream_output/bin/patchelf" --version)
[[ $expected_version == 'patchelf 0.19.2' ]]
expected_interpreter=$("$upstream_output/bin/patchelf" --print-interpreter "$upstream_output/bin/patchelf")
expected_patchelf_hash=$(nix hash convert --hash-algo sha256 --to sri "$(jq -r .patchelf.sha256 "$root/manual/06-flake-package-flake-compat/pins.json")")

expected_nixpkgs_hash=$(nix hash convert --hash-algo sha256 --to sri "$(jq -r .nixpkgs.sha256 "$root/manual/06-flake-package-flake-compat/pins.json")")
wrapper_drv=''
upstream_lock_hash=''

for relative in "${examples[@]}"; do
  approach=${relative%%/*}
  library=native
  if [[ $approach != flake && $approach != tack ]]; then library=flake-${relative##*-flake-}; fi
  example="$scratch/$relative"
  mkdir -p "$example"
  tar -C "$root/$relative" \
    --exclude='./result*' --exclude='*.tmp' --exclude=./next_lock.json \
    -cf - . | tar -C "$example" -xf -
  before=$(fingerprint "$example")
  [[ $(cat "$example/revision") == "$revision" &&
     $(cat "$example/patchelf-revision") == "$patchelf_revision" &&
     $(locked_revision "$approach" "$example" nixpkgs) == "$revision" &&
     $(locked_revision "$approach" "$example" patchelf) == "$patchelf_revision" ]]
  for pin in nixpkgs patchelf; do
    expression=$(source_expression "$approach" "$pin")
    source=$(cd "$example" && nix eval --impure --raw --expr "builtins.toString ($expression)")
    if [[ $pin == nixpkgs ]]; then
      check_hash "$source" "$expected_nixpkgs_hash"
    else
      check_hash "$source" "$expected_patchelf_hash"
      current_lock_hash=$(sha256sum "$source/flake.lock" | cut -d ' ' -f1)
      if [[ -z $upstream_lock_hash ]]; then upstream_lock_hash=$current_lock_hash; fi
      [[ $current_lock_hash == "$upstream_lock_hash" ]]
      upstream_nixpkgs=$(jq -r '.nodes.nixpkgs.locked.rev' "$source/flake.lock")
      [[ $upstream_nixpkgs == c69a9bffbecde46b4b939465422ddc59493d3e4d && $upstream_nixpkgs != "$revision" ]]
    fi
  done
  if [[ $approach == flake || $approach == tack ]]; then
    [[ ! -e "$example/flake-compat-revision" ]]
    if [[ $approach == flake ]]; then
      # Parent lock node names can change; follow the actual dependency edge.
      [[ $(jq -r '.nodes[.nodes.patchelf.inputs.nixpkgs].locked.rev' "$example/flake.lock") == "$upstream_nixpkgs" ]]
      jq -e '.nodes.root.inputs | has("flake-compat") | not' "$example/flake.lock" > /dev/null
    else
      jq -e 'has("flake-compat") | not' "$example/.tack/pins.lock.json" > /dev/null
    fi
  else
    adapter_revision=$(cat "$root/manual/06-flake-package-$library/$library-revision")
    expected_adapter_hash=$(nix hash convert --hash-algo sha256 --to sri "$(jq -r --arg n "$library" '.[$n].sha256' "$root/manual/06-flake-package-$library/pins.json")")
    [[ $(cat "$example/$library-revision") == "$adapter_revision" &&
       $(locked_revision "$approach" "$example" "$library") == "$adapter_revision" ]]
    expression=$(source_expression "$approach" "$library")
    adapter_source=$(cd "$example" && nix eval --impure --raw --expr "builtins.toString ($expression)")
    check_hash "$adapter_source" "$expected_adapter_hash"
    # Compare both adapters with the original upstream package, without overrides.
    expression=$(source_expression "$approach" patchelf)
    if [[ $library == flake-compat ]]; then
      adapter_expression="(import (/. + builtins.getEnv \"ADAPTER_SOURCE\") { src = ($expression); system = \"$system\"; }).outputs"
    else
      adapter_expression="(import (/. + builtins.getEnv \"ADAPTER_SOURCE\")).import-flake { src = ($expression); }"
    fi
    adapter_drv=$(cd "$example" && ADAPTER_SOURCE="$adapter_source" nix eval --impure --raw --expr "($adapter_expression).packages.\"$system\".default.drvPath")
    [[ $adapter_drv == "$upstream_drv" ]]
  fi

  if [[ $approach == flake ]]; then
    (cd "$example" && nix build path:.)
  elif [[ $approach == mana ]]; then
    (cd "$example" && nix-build -A patchelf-demo)
  else
    (cd "$example" && nix-build)
  fi
  [[ $("$example/result/bin/patchelf-demo" --version) == "$expected_version" ]]
  [[ $("$example/result/bin/patchelf-demo" --print-interpreter "$upstream_output/bin/patchelf") == "$expected_interpreter" ]]
  # The wrapper must reference the real upstream output, not just match its version.
  references=$(nix-store --query --references "$example/result")
  printf '%s\n' "$references" | grep -Fx "$upstream_output" > /dev/null
  current_wrapper=$(nix-store --query --deriver "$example/result")
  if [[ -z $wrapper_drv ]]; then wrapper_drv=$current_wrapper; fi
  [[ $current_wrapper == "$wrapper_drv" ]]
  [[ $(fingerprint "$example") == "$before" ]]
  printf '%s: pins, upstream lock, output dependency, matching wrapper, arguments, and unchanged files verified\n' "$relative"
done
printf '%s\n' 'Example 06 passed: 14 native/library implementations, with IFD disabled.'

./verify-unflake.sh 06 "$@"
./verify-with-inputs.sh 06 "$@"
printf '%s\n' 'Example 06 passed: all 26 implementations, with IFD disabled.'
