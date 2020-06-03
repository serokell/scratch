rec {
  # build nixos system from a list of configs
  # returns { options, config, pkgs, system }
  mkSystem = pkgs: imports: (import "${pkgs.path}/nixos" {
    configuration = { lib, ... }: {
      imports = imports;
      config.nixpkgs.pkgs = lib.mkForce pkgs; # shouldn't set it anywhere else tbh
    };
  });

  # disk image for a system
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

  # minimal nixos vm config with root ssh access for the specified key
  mkVmShim = ssh-key: { lib, ... }: {
    # platform setup
    boot.initrd.availableKernelModules = [ "virtio_net" "virtio_pci" "virtio_blk" ];
    fileSystems."/".device = "/dev/disk/by-label/nixos";
    boot.loader.grub.device = "/dev/vda";
    boot.loader.timeout = 0;

    # root ssh access
    services.openssh.enable = lib.mkForce true;
    services.openssh.ports = lib.mkForce [ 22 ];
    services.openssh.permitRootLogin = lib.mkForce "prohibit-password";
    users.users.root.openssh.authorizedKeys.keys = [ ssh-key ];
  };
}
