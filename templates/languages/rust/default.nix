{ pkgs ? import ./nix {} }: with pkgs;
let
  rc = rustChannelOf { channel = "1.36.0"; };
  rustPlatform = (makeRustPlatform {
    rustc = rc.rust;
    inherit (rc) cargo;
  }) // { rustcSrc = "${rc.rust-src}/lib/rustlib/src/rust/src"; };

  # Override rust-racer to use our Rust version, and disable tests (because they fail)
  racer = (rustracer.override { inherit rustPlatform; })
    .overrideAttrs (old: rec { preCheck = ""; doCheck = false; });

in
rec {
  thing = rustPlatform.buildRustPackage rec {
    name = "thing${version}";
    version = "0.1.0";
    src = gitignoreSource ./.;
    cargoSha256 = "0r964h4l04a3hi13gnmvg74j0x1k6akbaqyyag6fvmmb9l4fc8d9";
  };

  devshell =
    mkShell {
      name = "thing-shell";

      buildInputs = [
        rc.rust
        racer
      ];

      shellHook = ''
        export RUST_SRC_PATH="${rc.rust-src}/lib/rustlib/src/rust/src"
      '';
    };
}
