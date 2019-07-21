{ stdenv, rustPlatform, fetchFromGitHub, postgresql_11, zlib, openssl }:
let
  # master 20.07.2019 -- v1.4.2 doesn't seem to compile
  diesel-src = fetchFromGitHub {
    owner = "diesel-rs";
    repo = "diesel";
    rev = "0b6c59e36cef3faea0184404e43e3db4739d1193";
    sha256 = "01lx9b9m2y5rbralpdigrm8nqd72sij4ynpqf5icix7li73l3dvc";
  };

  lockfile = ./Cargo.lock;
  diesel_cli-src = stdenv.mkDerivation {
    name = "diesel-src-1.4.0";
    src = "${diesel-src}";
    installPhase = ''
        mkdir -p $out
        cp -R $src/diesel_cli/* $out/
        cp ${lockfile} $out/Cargo.lock
    '';
  };
in

rustPlatform.buildRustPackage rec {
  name = "diesel_cli-${version}";
  version = "1.4.0";
  src = "${diesel_cli-src}";
  cargoSha256 = "056gv4yaa2b0vq7b6jww0hb6jjm0hnrzvh6vss8jgk7nkndyc7ph";
  cargoBuildFlags = [
    "--no-default-features"
    "--features" "postgres"
  ];
  # The test suite wants to run sqlite/mysql tests
  doCheck = false;
  buildInputs = [ postgresql_11 zlib openssl ];
}
