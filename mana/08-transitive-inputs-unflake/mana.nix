{
  name = "unflake-consumer";
  entrypoint = ./entrypoint.nix;
  dependencies = {
    git-hooks-nix = { url = "github:cachix/git-hooks.nix/aa9f40c906904ebd83da78e7f328cd8aeaeae785"; entrypoint = null; };
    upstream-flake-compat = { url = "github:edolstra/flake-compat/0f9255e01c2351cc7d116c072cb317785dd33b33"; entrypoint = null; };
    flake-parts = { url = "github:hercules-ci/flake-parts/205b12d8b7cd4802fbcb8e8ef6a0f1408781a4f9"; entrypoint = null; };
    gitignore = { url = "github:hercules-ci/gitignore.nix/637db329424fd7e46cf4185293b9cc8c88c95394"; entrypoint = null; };
    nixpkgs = { url = "github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83"; entrypoint = null; };
    patchelf = { url = "github:NixOS/patchelf/3e996dbef1fa0658012f8dd290bddcf0302acade"; entrypoint = null; };
  };
}
