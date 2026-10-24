# Seeds for regenerating the graph. Normal builds read the native lock instead.
let
  parentRevision = builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile ./revision);
  patchelfRevision = builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile ./patchelf-revision);
  # Share our parent with every upstream nixpkgs reference.
  upstreamNixpkgs = "github:NixOS/nixpkgs/${parentRevision}";
in
{
  nixpkgs.url = "github:NixOS/nixpkgs/${parentRevision}";
  patchelf.url = "github:NixOS/patchelf/${patchelfRevision}";

  # Unflake ignores upstream locks and nested input overrides. These rules
  # select the intended nixpkgs for all spellings and freeze development inputs.
  _unflake.dedupRules = [
    # gitignore declares a registry-style input rather than a GitHub URL.
    {
      when = { type = "indirect"; id = "nixpkgs"; };
      replace = upstreamNixpkgs;
    }
    # This flake-parts snapshot declares nixpkgs-lib as a full nixpkgs tarball.
    {
      when = {
        type = "tarball";
        url = "https://github.com/NixOS/nixpkgs/archive/5487e69da40cbd611ab2cadee0b4637225f7cfae.tar.gz";
      };
      replace = upstreamNixpkgs;
    }
    # Merge upstream branches (including nixpkgs-stable). Our fixed root input
    # already has a revision, so this rule leaves its declaration alone.
    {
      when = { type = "github"; owner = "nixos"; repo = "nixpkgs"; rev = null; };
      replace = upstreamNixpkgs;
    }
    # Keep development inputs reproducible too, although package builds are lazy
    # and do not need to evaluate their development outputs.
    {
      when = { type = "github"; owner = "hercules-ci"; repo = "flake-parts"; };
      replace = "github:hercules-ci/flake-parts/205b12d8b7cd4802fbcb8e8ef6a0f1408781a4f9";
    }
    {
      when = { type = "github"; owner = "cachix"; repo = "git-hooks.nix"; };
      replace = "github:cachix/git-hooks.nix/aa9f40c906904ebd83da78e7f328cd8aeaeae785";
    }
    {
      when = { type = "github"; owner = "hercules-ci"; repo = "gitignore.nix"; };
      replace = "github:hercules-ci/gitignore.nix/637db329424fd7e46cf4185293b9cc8c88c95394";
    }
    {
      when = { type = "github"; owner = "edolstra"; repo = "flake-compat"; };
      replace = "github:edolstra/flake-compat/0f9255e01c2351cc7d116c072cb317785dd33b33";
    }
  ];
}
