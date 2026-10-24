{
  name = "flake-package-consumer";
  entrypoint = ./entrypoint.nix;
  dependencies = {
    nixpkgs = { url = "github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83"; entrypoint = null; };
    patchelf = { url = "github:NixOS/patchelf/3e996dbef1fa0658012f8dd290bddcf0302acade"; entrypoint = null; };
    flake-inputs = { url = "github:fricklerhandwerk/flake-inputs/5c1279c5b5dc81dfd245fc4d072446fc56f341c7"; entrypoint = null; };
  };
}
