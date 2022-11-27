{ lib, pkgs, config, modulesPath, ... }:
{

  deployment = {
    targetHost = "192.168.20.138";
    targetPort = 22;
    targetUser = "mhelton";
  };

  networking.hostName = "gaia0";

  # tailscale
  services.tailscale-autoconnect = {
    enable = true;
    extraTailscaleArgs = [ "--operator=caddy" ];
  };

  services.nomad-server = {
    enable = true;
    nomadPackage = pkgs.nomad_1_4;
  };

}
