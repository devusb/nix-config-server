{ lib, pkgs, config, modulesPath, ... }:
{

  deployment = {
    targetHost = "192.168.10.247";
    targetPort = 22;
    targetUser = "nixos";
  };

  systemd.network.links."10-wan" = {
    matchConfig.PermanentMACAddress = "e4:5f:01:d3:28:e9";
    linkConfig.Name = "wan0";
  };

}
