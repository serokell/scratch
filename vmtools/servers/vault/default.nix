{ config, lib, pkgs, ... }:

{
  networking.hostName = "test2";

  # runs vault on port 8200
  services.vault = {
    enable = true;
    package = pkgs.vault-bin;
    address = ":8200";
    extraConfig = "ui = true";
  };
}
