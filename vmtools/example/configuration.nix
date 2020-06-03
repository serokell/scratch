{ config, lib, pkgs, ... }:

# example of a nixos config
{
  networking.firewall.enable = false;
  networking.firewall.allowPing = true;

  # runs vault on port 8200
  services.vault = {
    enable = true;
    package = pkgs.vault-bin;
    address = ":8200";
    extraConfig = "ui = true";
  };
}
