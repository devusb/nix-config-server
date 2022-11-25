{ lib, pkgs, config, modulesPath, ... }:
{

  deployment = {
    targetHost = "192.168.20.139";
    targetPort = 22;
    targetUser = "mhelton";
  };

  networking.hostName = "gaia1";

  # tailscale
  services.tailscale-autoconnect = {
    enable = true;
  };

}
