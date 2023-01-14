{ lib, pkgs, config, modulesPath, ... }:
{

  system.stateVersion = "22.11";

  deployment = {
    targetHost = "192.168.20.106";
    targetPort = 22;
    targetUser = "root";
  };

  networking.hostName = "attic";

  services.tailscale-serve = {
    enable = true;
    port = 8080;
    funnel = true;
  };

  sops.secrets.attic_secret = {
    sopsFile = ../secrets/attic.yaml;
  };
  services.atticd = {
    enable = true;
    credentialsFile = config.sops.secrets.attic_secret.path;
    settings = {
      storage = {
        type = "local";
        path = "/nix-cache";
      };
    };
  };
  systemd.services.atticd.serviceConfig.ReadWritePaths = "/nix-cache";

}
