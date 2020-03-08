let
  sources = import ./nix/sources.nix;
in with import sources.nixpkgs {};
let
  installWrapped = {
    src,
      name ? lib.head (lib.splitString "." (builtins.baseNameOf src)),
      buildInputs
  }: runCommand "skl-scratch-${name}" {
    inherit buildInputs;
    isPy = lib.hasSuffix ".py" (toString src);
  } ''
  set +x
  mkdir -p $out/bin
  if [ "$isPy" -eq 1 ]; then
     cat <<EOF - ${src} > $out/bin/${name}
  #!/usr/bin/env python
  import os
  os.environ['PATH'] += "${lib.makeBinPath buildInputs}"
  EOF
  else
     cat <<EOF - ${src} > $out/bin/${name}
  #!/usr/bin/env bash
  PATH = $PATH:"${lib.makeBinPath buildInputs}"
  EOF
  fi
  chmod +x $out/bin/${name}
  patchShebangs $out/bin
'';
  scripts = {
    # restore-jupiter-state = installWrapped {
    #   src = ./scripts/restore-jupiter-state.sh;
    #   buildInputs = [ cli53 ];
    # };
    update-niv = installWrapped {
      src = ./scripts/update-niv.sh;
      buildInputs = [ jq gitAndTools.hub niv ];
    };
    release-binary = installWrapped {
      src = ./scripts/release-binary.sh;
      buildInputs = [ gitAndTools.hub git ];
    };
    update-stack-shas = installWrapped {
      src = ./scripts/update-stack-shas.py;
      buildInputs = [
        (python3.withPackages (p: with p; [ pyyaml ]))
        nix-prefetch-git
      ];
    };
    upload-daemon = haskellPackages.callPackage ./scripts/upload-daemon {};
  };
  plugins = {
    simdjson = import ./nix-plugins/simdjson { inherit pkgs; };
    importzip = import ./nix-plugins/importzip { inherit pkgs; };
  };
in
symlinkJoin rec {
  name = "serokell-scratch";
  passthru = { inherit scripts plugins; };
  paths = lib.collect lib.isDerivation passthru;
}
