let
  hs-nix = import (builtins.fetchTarball https://github.com/input-output-hk/haskell.nix/archive/master.tar.gz);
  nixpkgs-src = {
    serokell = builtins.fetchTarball https://github.com/serokell/nixpkgs/archive/master.tar.gz;
    oldstable = builtins.fetchTarball channel:nixos-19.09;
    newstable = builtins.fetchTarball channel:nixos-20.03;
  };
  nixpkgs = builtins.mapAttrs (name: value: import value hs-nix) nixpkgs-src;
in
nixpkgs.serokell.lib.recurseIntoAttrs (builtins.mapAttrs (name: value: value.haskell-nix.haskellNixRoots) nixpkgs)
