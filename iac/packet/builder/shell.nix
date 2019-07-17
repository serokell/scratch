{ pkgs ? import ./../../../nix {} }: with pkgs;

let
  inherit (builtins) toString;
  inherit (lib) concatStringsSep;

  tf = terraform_0_12.withPlugins(p: with p; [
    aws
    packet
  ]);
in
  mkShell {
    buildInputs = [
      tf
      terraform-docs
      awscli
      direnv
      jq
    ];

    NIX_PATH = concatStringsSep ":" [
      "nixpkgs=${toString pkgs.path}"
    ];
  }
