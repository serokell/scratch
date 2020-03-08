{ pkgs ? import <nixpkgs> {} }:
with pkgs;
let
  miniz = stdenv.mkDerivation rec {
    pname = "miniz";
    version = src.rev;
    src = fetchFromGitHub {
      owner = "richgel999";
      repo = pname;
      rev = "e48d8bab887deeddb608d713128529c9261bf9e7";
      sha256 = "1agrcwv2cqrzc0za5f8adk7cf1qyj02l4n21hv819cj8jr4lflix";
    };
    nativeBuildInputs = [ cmake zip ];
    configurePhase = "true";
    buildPhase = "bash amalgamate.sh";
    installPhase = ''
      install -Dt $out/include amalgamation/miniz.{h,c}
    '';
  };
in
stdenv.mkDerivation {
  name = "nix-plugin-importzip";
  buildInputs = [ nix boost ]; # pythonPackages.pywatchman ];
  src = ./.;
  prePatch = ''
    cp ${miniz}/include/* .
  '';
}
