{ lib, ... }:
{
  imports = [
    ./..
  ];

  services.fstrim.enable = true;
  hardware.cpu.amd.updateMicrocode = true;
  nixpkgs.config.allowUnfree = true;
  hardware.enableAllFirmware = true;
  nix.maxJobs = 48;

  boot = {
    kernelParams =  [ "console=ttyS1,115200n8" ];
    initrd.availableKernelModules = ["xhci_pci" "ahci" "mpt3sas" "sd_mod"];
    kernelModules = [ "dm_multipath" "dm_rount_robin" "kvm-amd"];
    loader = {
      systemd-boot.enable = lib.mkForce false;
      grub = {
        extraConfig = ''
          serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
          terminal_output serial console
          terminal_input serial console
        '';
        efiSupport = true;
        device = "nodev";
        efiInstallAsRemovable = true;

      };
      efi = {
        efiSysMountPoint = "/boot/efi";
        canTouchEfiVariables = lib.mkForce false;
      };
    };
  };

  fileSystems = {
    "/" = {
      label = "nixos";
      fsType = "ext4";
    };
    "/boot/efi" = {
      device = "/dev/sda1";
      fsType = "vfat";
    };
  };

  networking.bonds.bond0 = {
    driverOptions = {
      mode = "802.3ad";
      xmit_hash_policy = "layer3+4";
      lacp_rate = "fast";
      downdelay = "200";
      miimon = "100";
      updelay = "200";
    };

    interfaces = [
      "enp5s0f0" "enp5s0f1"
    ];
  };

  networking.nameservers = [
    "147.75.207.207"
    "147.75.207.208"
  ];

  networking.dhcpcd.enable = false;
  networking.defaultGateway.interface = "bond0";
  networking.defaultGateway6.interface = "bond0";
  networking.interfaces.bond0.useDHCP = false;

  swapDevices = [{label = "swap";}];
}
