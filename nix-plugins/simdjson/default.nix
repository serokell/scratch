{ pkgs ? import <nixpkgs> {} }:
with pkgs;
let
  simdjson = stdenv.mkDerivation rec {
    pname = "simdjson";
    version = src.rev;
    src = fetchFromGitHub {
      owner = "lemire";
      repo = pname;
      rev = "66a28072104e8df327731fc8530a4f06e384dad5";
      sha256 = "0h7bdc4h7q7bfw2lnh2r7afypw3sqw1yvlr242jls8mwakapgjwq";
    };
    postPatch = ''
      patchShebangs amalgamation.sh
    '';
    buildPhase = "make amalgamate";
    installPhase = ''
      install -Dt $out/include singleheader/simdjson.{h,cpp}
    '';
  };
in
stdenv.mkDerivation {
  name = "nix-plugin-simdjson";
  buildInputs = [ nix boost ];
  src = ./.;
  prePatch = ''
    cp ${simdjson}/include/* .
  '';
}
