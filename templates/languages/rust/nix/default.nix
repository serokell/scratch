{ sources ? import ./sources.nix }:

import sources.nixpkgs
  { overlays =
    [ (_: pkgs:
        { niv = import sources.niv {};
          inherit (import sources.gitignore { inherit (pkgs) lib; }) gitignoreSource;
        }
      )
      (import sources.nixpkgs-mozilla)
    ];

    config = {};
  }
