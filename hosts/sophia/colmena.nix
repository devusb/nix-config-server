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
    extraTailscaleArgs = [ "--advertise-exit-node" "--advertise-routes=192.168.0.0/16" "--accept-routes" "--accept-dns=false" ];
  };

}
