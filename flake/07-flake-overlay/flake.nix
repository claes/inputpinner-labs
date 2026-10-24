{
  description = "07: Apply an upstream flake overlay to our own nixpkgs";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    patchelf.url = "github:NixOS/patchelf/master";
    # Retain upstream locks: using an overlay needs no input-sharing rule.
  };
  outputs = { nixpkgs, patchelf, ... }: {
    packages = builtins.listToAttrs (map (system:
      let
        # The overlay builds its package with this parent package set.
        pkgs = import nixpkgs {
          inherit system;
          config = {};
          overlays = [ patchelf.overlays.default ];
        };
      in {
        name = system;
        value = {
          default = pkgs.patchelf-new;
          patchelf-new = pkgs.patchelf-new;
        };
      }) [ "x86_64-linux" "i686-linux" "aarch64-linux" ]);
  };
}
