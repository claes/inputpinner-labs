{ system ? builtins.currentSystem }:
let
  sources = import ./lon.nix;
  pkgs = import sources.nixpkgs { inherit system; config = {}; overlays = []; };
in
pkgs.stdenvNoCC.mkDerivation {
  name = "systems.nix";
  src = sources.systems;
  # Patch the build's unpacked copy, preserving the immutable pinned source.
  patches = [ ./local.patch ];
  # Refuse fuzzy matches, reversed patches, and interactive questions.
  patchFlags = [ "-p1" "--fuzz=0" "--forward" "--batch" ];
  dontConfigure = true;
  dontBuild = true;
  # The dependency is Nix data; install it without evaluating a build output.
  installPhase = ''
    runHook preInstall
    cp default.nix "$out"
    runHook postInstall
  '';
}
