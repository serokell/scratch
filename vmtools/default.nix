rec {
  ssh-key = pkgs.lib.fileContents ./data/id_rsa.pub;

  # returns { options, config, pkgs, system }
  mkSystem = pkgs: imports: (import "${pkgs.path}/nixos" {
    configuration = { lib, ... }: {
      imports = imports;
      config.nixpkgs.pkgs = lib.mkForce pkgs;
    };
  });

  # same but allows to set `specialArgs`
  mkSystemSpecial = pkgs: specialArgs: imports:
    let
      eval = (import "${pkgs.path}/nixos/lib/eval-config.nix" {
        system = builtins.currentSystem;
        modules = [ ({ lib, ... }: {
          imports = imports;
          config.nixpkgs.pkgs = lib.mkForce pkgs;
        })];
        specialArgs = specialArgs;
      });
    in {
      inherit (eval) pkgs config options;
      system = eval.config.system.build.toplevel;
    };

  mkDiskImage = { diskSizeMb, system }: import "${system.pkgs.path}/nixos/lib/make-disk-image.nix" {
    pkgs = system.pkgs;
    lib = system.pkgs.lib;
    config = system.config;
    diskSize = diskSizeMb;
    partitionTableType = "legacy"; # mbr with a single partition
    fsType = "ext4";
    label = "nixos";
    format = "qcow2";
  };

  mkVmShim = ssh-key: { lib, ... }: {
    # modules needed for vm i guess
    boot.initrd.availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_mmio" "virtio_blk" "virtio_scsi" ];
    boot.initrd.kernelModules = [ "virtio_balloon" "virtio_console" "virtio_rng" ];

    boot.growPartition = true;
    boot.loader.grub.device = "/dev/vda";
    boot.loader.timeout = 0;
    fileSystems."/".device = "/dev/disk/by-label/nixos";
    fileSystems."/".fsType = "ext4";
    fileSystems."/".autoResize = true;

    # root ssh access
    services.openssh.enable = lib.mkForce true;
    services.openssh.ports = lib.mkForce [ 22 ];
    services.openssh.permitRootLogin = lib.mkForce "prohibit-password";
    users.users.root.openssh.authorizedKeys.keys = [ ssh-key ];

    # disable dhcp arp probing to get network quicker
    networking.dhcpcd.extraConfig = ''
      noarp
    '';
  };

  debug-shim = { lib, ... }: {
    # disable firewall
    networking.firewall.enable = lib.mkForce false;

    # allow ping
    networking.firewall.allowPing = lib.mkForce true;

    # autologin
    services.getty.autologinUser = lib.mkForce "root";
  };

  pkgs = import <nixpkgs> {};
  lib = pkgs.lib;

  renderJSON = name: data: pkgs.writeText name (builtins.toJSON data);

  vm-shim = mkVmShim ssh-key;

  bare-disk-image = mkDiskImage {
    diskSizeMb = 2*1024; # 2G
    system = mkSystem pkgs [ vm-shim debug-shim ];
  };

  ubuntu-cloud-init = pkgs.writeText "cloud-init" ''
    #cloud-config
    users:
      - name: ubuntu
        ssh-authorized-keys:
          - "${ssh-key}"
        sudo: ['ALL=(ALL) NOPASSWD:ALL']
        groups: sudo
        shell: /bin/bash
    chpasswd:
      list: |
         ubuntu:1
      expire: False
  '';

  extra-shim = { config, lib, pkgs, ... }: {
    imports = [ debug-shim ];

    # extra config for all vms

    environment.systemPackages = with pkgs; [
      strace ranger psmisc vim htop smem
    ];
  };

  configs = {
    nginx = ./servers/nginx;
    vault = ./servers/vault;
  };

  vm = lib.flip lib.mapAttrs configs (_name: config:
    mkSystem pkgs [ vm-shim extra-shim config ]
  );

  deployment = renderJSON "deployment.json" {
    "TEST1_IP_ADDRESS" = vm.nginx.system;
    "TEST2_IP_ADDRESS" = vm.vault.system;
  };
}
