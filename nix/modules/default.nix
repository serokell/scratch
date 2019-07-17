{ lib, pkgs, ... }:
{
  services.smartd = {
    enable = true;
    notifications.mail = {
      enable = true;
      recipient = "operations@serokell.io";
    };
  };

  services.postfix.enable = true;
  services.openssh.enable = true;
}
