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

  services.nfs = {
    server = {
      enable = true;
      createMountPoints = true;
      exports = ''
        /var/lib/exports/nomad-volumes (rw,async,no_subtree_check,no_root_squash,insecure)
      '';
    };
  };

}
