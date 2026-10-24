# 07: Apply a flake overlay with lon

Apply the pinned [patchelf
overlay](https://github.com/NixOS/patchelf/blob/3e996dbef1fa0658012f8dd290bddcf0302acade/flake.nix)
to the consumer’s nixpkgs and build its added package:

```sh
nix-build
./result/bin/patchelf --version
```

Expect `patchelf 0.19.2`. `patchelf-new` is the Nix attribute name; the
executable remains `bin/patchelf`. Unlike 06, this builds the overlay recipe
with the parent package set instead of wrapping upstream’s prebuilt package
output.

Lon 0.8.0 supplies the same source trees as 06. flake-compat exposes the
upstream overlay, and the parent nixpkgs import applies it before selecting
`patchelf-new`.

The source resolver does not apply overlays. Keeping that step explicit shows
how a pinned upstream function affects the consumer’s package set.

Alternative considered: Replacing `pkgs.patchelf` with a prebuilt upstream
output would retain upstream’s compiler. Applying the exported overlay lets its
recipe use parent dependencies and preserves the original `pkgs.patchelf`
attribute.

Source pins, generated resolvers, seed files, and version records are copied
unchanged from [06-flake-package](../06-flake-package). No initialization or
pinner CLI is needed to build. For regeneration, follow 06’s maintenance setup
and use this directory’s `init.sh` in a disposable copy without its generated
files.

The upstream lock supplies helper functions for overlay evaluation. The selected
recipe uses the parent toolchain, while upstream’s package outputs keep their
own package set. The overlay adds `patchelf-new` alongside the parent’s existing
`patchelf`, without an input-sharing rule or lock rewrite.

`../../verify-07.sh` checks pins, upstream locks, matching overlay builds,
parent build dependencies, version output, and unchanged files in fresh copies
with spaces in their paths. It also compares with 06’s upstream package and
confirms that plain parent nixpkgs has no `patchelf-new` attribute.
