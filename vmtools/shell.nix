let
  sources = import ./nix/sources.nix;
  pkgs = import <nixpkgs> {};
  nixops-rev = "2454e89633b6e660be0ddbc58d233cf88ee7836f";
  nixops-src = fetchTarball {
    url = "https://github.com/NixOS/nixops/archive/${nixops-rev}.tar.gz";
    sha256 = "0vdyr4cba7f1lvvc8gxap99g17y8lqpzrkg4q6jkifj6dgm2wwls";
  };
  nixops = import nixops-src {};

in pkgs.mkShell {
  buildInputs = [
    # terraform with libvirt provider
    (pkgs.terraform.withPlugins (p: with p; [ libvirt ]))

    # python3 with nixops for the "deploy-all.py" script
    (pkgs.python3.withPackages (ps: with ps; [ nixops ]))
  ];
}
