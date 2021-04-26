{ config, lib, pkgs, ... }:

{
  networking.hostName = "test1";

  # serves "Welcome to nginx" page on port 80
  services.nginx.enable = true;
}
