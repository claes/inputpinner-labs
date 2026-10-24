{
  description = "04: Update one of two independent nixpkgs inputs";
  inputs = {
    stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };
  outputs = { stable, unstable, ... }: {
    packages = builtins.listToAttrs (map (system: {
      name = system;
      value = {
        # Each output uses its own locked package set.
        stable = (import stable { inherit system; config = {}; overlays = []; }).hello;
        unstable = (import unstable { inherit system; config = {}; overlays = []; }).hello;
      };
    }) [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ]);
  };
}
