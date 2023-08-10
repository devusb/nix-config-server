{ lib, pkgs, config, modulesPath, ... }:
{

  deployment = {
    targetHost = "192.168.10.1";
    targetPort = 22;
    targetUser = "mhelton";
  };

  # tailscale
  services.tailscale-autoconnect = {
    enable = true;
    extraTailscaleArgs = [ "--advertise-exit-node" "--advertise-routes=192.168.10.0/23,192.168.20.0/23,192.168.30.0/24,192.168.40.0/23,192.168.99.0/24" "--accept-routes" "--accept-dns=false" ];
  };

}
