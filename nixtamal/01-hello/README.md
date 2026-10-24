# 01 — GNU Hello with Nixtamal

## Goal and approach

Build an existing package from one pinned nixpkgs input.

A KDL manifest describes an archive and its freshness command. Native setup generates the resolver; native locking records the revision and hash. The entrypoint imports nixpkgs.

## Main challenges

Use evaluation-time fetching to bootstrap nixpkgs. Start with a literal commit as the freshness value so initialization cannot follow a moving branch.

## Alternatives considered

In the tested 1.5.4, `set-up --nixpkgs-revision` still fetched the branch tip. Setup without default inputs plus an explicit manifest gives the intended revision. Build-time fetchers are unnecessary here.

## Build and run

Requires Nix. Nixtamal is only needed to initialize or update pins. The generated pins are included; build directly:

```sh
nix-build
LC_ALL=C ./result/bin/hello
```

Expect `Hello, world!`. Validated on `x86_64-linux` with the same revision and
Hello derivation as the other examples; building leaves inputs unchanged.

## Initialize or update

To reproduce the setup in a directory without generated pins:

```sh
nix shell github:NixOS/nixpkgs/2efa67fd26b6df417c33e4603185c701f260dd83#nixtamal.bin --command ./init.sh
```

Keep `nix/tamal/manifest.kdl`, `lock.json`, and generated `default.nix` and `versions.txt` in version control.
Run updates in a shell containing the same tool, using the pinned `nix shell` reference above.

To explore updates in a disposable copy:

First replace the manifest's literal freshness command with:

```kdl
fresh-cmd {
    $ git ls-remote "https://github.com/NixOS/nixpkgs.git" --refs "refs/heads/nixos-26.05"
    | cut -f1
}
```

```sh
nixtamal refresh --no-tui nixpkgs
```

Review the lock diff. Updating intentionally leaves the common starting revision.
See [lab validation and prerequisites](../../README.md) for tool versions and Git configuration notes.

Reference: [Nixtamal documentation](https://nixtamal.toast.al/manpage/nixtamal-set-up.1/).
