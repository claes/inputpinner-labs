{
  description = "08: Share parent nixpkgs with an upstream flake package";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    patchelf.url = "github:NixOS/patchelf/master";
    # Reuse the parent's node, including through upstream follows chains.
    patchelf.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { nixpkgs, patchelf, ... }: {
    # Match the platforms exported by this upstream flake.
    packages = builtins.listToAttrs (map (system:
      let
        pkgs = import nixpkgs { inherit system; config = {}; overlays = []; };
        upstreamPackage = patchelf.packages.${system}.default;
      in {
        name = system;
        # Interpolation records the upstream output as a runtime dependency.
        value.default = pkgs.writeShellScriptBin "patchelf-demo" ''
          exec ${upstreamPackage}/bin/patchelf "$@"
        '';
      }) [ "x86_64-linux" "i686-linux" "aarch64-linux" ]);
  };
}
