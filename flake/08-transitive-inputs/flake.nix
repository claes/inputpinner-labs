{
  description = "08: Hello and upstream patchelf share one nixpkgs pin";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    patchelf.url = "github:NixOS/patchelf/master";
    # Upstream builds with the same nixpkgs that supplies our Hello.
    patchelf.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { nixpkgs, patchelf, ... }: {
    # Match the platforms supported by this upstream snapshot.
    packages = builtins.listToAttrs (map (system:
      let
        pkgs = import nixpkgs { inherit system; config = {}; overlays = []; };
      in {
        name = system;
        value = {
          hello = pkgs.hello;
          # Consume the upstream flake output, with the follows edge applied.
          patchelf = patchelf.packages.${system}.default;
        };
      }) [ "x86_64-linux" "i686-linux" "aarch64-linux" ]);
  };
}
