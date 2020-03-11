{ mkDerivation, async, base, bytestring, conduit, conduit-extra
, optparse-applicative, process, prometheus, stdenv
, streaming-commons, text
}:
mkDerivation {
  pname = "upload-daemon";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [
    async base bytestring conduit conduit-extra optparse-applicative
    process prometheus streaming-commons text
  ];
  description = "Upload daemon for nix post-build-hook";
  license = stdenv.lib.licenses.mpl20;
}
