{ sources ? import ./sources.nix }:
let
  overlays = [
    (self: _: {
      inherit (self.callPackage sources.gitignore {}) gitignoreSource;
      niv = self.callPackage sources.niv {};
    })
  ];

in

import sources.nixpkgs { inherit overlays; config = {}; }
