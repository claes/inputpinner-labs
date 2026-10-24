{
  name = "transitive-input-consumer";
  entrypoint = ./entrypoint.nix;
  dependencies = {
    nixpkgs = { url = "github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83"; entrypoint = null; };
    patchelf = { url = "github:NixOS/patchelf/3e996dbef1fa0658012f8dd290bddcf0302acade"; entrypoint = null; };
    flake-compat = { url = "github:NixOS/flake-compat/5edf11c44bc78a0d334f6334cdaf7d60d732daab"; entrypoint = null; };
  };
}
