rec {
  pkgs = import <nixpkgs> {};
  config-example = ./configuration.nix;
  ssh-key = builtins.readFile ./out/id_rsa.pub;

  vmtools = import ../.;
  inherit (vmtools) mkSystem mkDiskImage mkVmShim;

  vm-shim = mkVmShim ssh-key;

  # bare nixos vm disk image with root ssh access
  bare-disk-image = mkDiskImage {
    diskSizeMb = 10*1024; # 10G
    system = mkSystem pkgs [ vm-shim ];
  };

  # system example, don't forget to add 'vm-shim' here or else you'll lose ssh access
  machine = mkSystem pkgs [ vm-shim config-example ];
}
