{ mkDerivation, async, base, bytestring, fmt, network-simple
, process, prometheus, stdenv, text, optparse-applicative
}:
mkDerivation {
  pname = "upload-daemon";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [
    async base bytestring network-simple process prometheus text
    optparse-applicative
  ];
  description = "Upload daemon for nix post-build-hook";
  license = stdenv.lib.licenses.mpl20;
}
