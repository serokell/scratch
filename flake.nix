{
  inputs.nixpkgs.url = "github:serokell/nixpkgs/master";

  outputs = { self, nixpkgs }: {
    overlay = final: prev:
      with final;
      let
        installWrapped = { src
          , name ? lib.head (lib.splitString "." (builtins.baseNameOf src))
          , buildInputs }:
          runCommand "skl-scratch-${name}" {
            inherit buildInputs;
            passthru = { inherit src name; };
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
            PATH=$PATH:"${lib.makeBinPath buildInputs}"
            EOF
            fi
            chmod +x $out/bin/${name}
            patchShebangs $out/bin
          '';
      in {
        scratch = {
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
              buildInputs = [ gh git nix ];
            };
            update-stack-shas = installWrapped {
              src = ./scripts/update-stack-shas.py;
              buildInputs = [
                (python3.withPackages (p: with p; [ pyyaml ]))
                nix-prefetch-git
              ];
            };
            upload-daemon =
              haskellPackages.callPackage ./scripts/upload-daemon { };
          };
          plugins = {
            simdjson = import ./nix-plugins/simdjson { inherit pkgs; };
            importzip = import ./nix-plugins/importzip { inherit pkgs; };
          };
        };
      };

    packages = builtins.mapAttrs (_: pkgs:
      let pkgs' = pkgs.extend self.overlay;
      in pkgs'.scratch.scripts // pkgs'.scratch.plugins) nixpkgs.legacyPackages;

    apps = builtins.mapAttrs (_:
      builtins.mapAttrs (name: pkg: {
        type = "app";
        program = "${pkg}/bin/${name}";
      })) self.packages;

    defaultPackage = builtins.mapAttrs (arch: pkgs:
      nixpkgs.legacyPackages.${arch}.symlinkJoin rec {
        name = "serokell-scratch";
        paths = builtins.attrValues pkgs;
      }) self.packages;
  };
}
