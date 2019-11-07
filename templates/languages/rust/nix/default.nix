{ sources ? import ./sources.nix }:

import sources.nixpkgs
  { overlays =
    [ (self: super:
        let
          channel = self.rustChannelOf { channel = "1.38.0"; };
        in rec
          { niv = import sources.niv {};
            inherit (import sources.gitignore { inherit (self) lib; }) gitignoreSource;
            rust-full = channel.rust;
            inherit (channel) rust-src;

            rustPlatform = (self.makeRustPlatform {
              rustc = channel.rust;
              inherit (channel) cargo;
            }) // { rustcSrc = "${channel.rust-src}/lib/rustlib/src/rust/src"; };


            # Override rust-racer to use our Rust version, and disable tests (because they fail)
            racer = (super.rustracer.override { inherit rustPlatform; })
              .overrideAttrs (old: rec { preCheck = ""; doCheck = false; });
          }
        )
        (import sources.nixpkgs-mozilla)
        (import ./pkgs)
    ];

    config = {};
  }
