{
  name = "transitive-inputs-consumer";
  entrypoint = ./entrypoint.nix;
  dependencies = {
    nixpkgs = { url = "github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83"; entrypoint = null; };
    patchelf = { url = "github:NixOS/patchelf/3e996dbef1fa0658012f8dd290bddcf0302acade"; entrypoint = null; };
    with-inputs = { url = "github:denful/with-inputs/641d01ef95eae1aeaa257ffd48102ab9a308f2a2"; entrypoint = null; };
    flake-parts = { url = "github:hercules-ci/flake-parts/205b12d8b7cd4802fbcb8e8ef6a0f1408781a4f9"; entrypoint = null; };
    git-hooks-nix = { url = "github:cachix/git-hooks.nix/aa9f40c906904ebd83da78e7f328cd8aeaeae785"; entrypoint = null; };
  };
}
