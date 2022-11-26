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

  services.nomad = {
    enable = true;
    settings = {
      datacenter = "dc1";
      client = {
        enabled = true;
        servers = [ "gaia0" ];
        network_interface = "tailscale0";
      };
    };
  };

  services.consul = {
    enable = true;
    interface.bind = "tailscale0";
    extraConfig = {
      datacenter = "dc1";
      retry_join = [ "gaia0" ];
    };
  };

}
