{ pkgs ? import ./nix {} }: with pkgs;
let
  src = gitignoreSource ./.;
  version = "0.1.0";
in rec {
  thing = rustPlatform.buildRustPackage rec {
    inherit src version;
    name = "thing-${version}";
    cargoSha256 = "0wg5absg2lk9q8lycc88kf3wfz3vz42flp1y2cl0i2xndvrsrp9n";
    buildInputs = [ postgresql_11 zlib openssl ];
  };

  devshell =
    mkShell {
      name = "thing-shell";

      buildInputs = [
        rust-full
        racer
        postgresql_11.lib
        diesel_cli
      ];

      shellHook = ''
        export RUST_SRC_PATH="${rust-src}/lib/rustlib/src/rust/src"
        export RUST_BACKTRACE=1
      '';
    };
}
