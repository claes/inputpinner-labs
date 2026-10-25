# Expose the system explicitly so the same pins can be used on another platform.
{ system ? builtins.currentSystem }:
let
  sources = import ./nix/tamal { inherit system; };
  # Empty config and overlays exclude personal Nixpkgs settings from this example.
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
in
# This example patches Nix data, so a compiler would add no useful build step.
pkgs.stdenvNoCC.mkDerivation {
  name = "systems.nix";
  src = sources.systems;
  # Patch the build's unpacked copy, preserving the immutable pinned source.
  patches = [ ./local.patch ];
  # Refuse fuzzy matches, reversed patches, and interactive questions.
  patchFlags = [ "-p1" "--fuzz=0" "--forward" "--batch" ];
  # Only unpacking, patching and installation are needed for this data file.
  dontConfigure = true;
  dontBuild = true;
  # The dependency is Nix data; install it without evaluating a build output.
  installPhase = ''
    runHook preInstall
    cp default.nix "$out"
    runHook postInstall
  '';
}
