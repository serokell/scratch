{
  boot.kernelModules = [ "ipmi_watchdog" ];

  boot.loader.grub = {
    enable = true;
    version = 2;
  };
}
