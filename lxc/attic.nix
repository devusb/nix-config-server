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
      chunking = {
        nar-size-threshold = 64 * 1024;
        min-size = 65536;
        avg-size = 131072;
        max-size = 262144;
      };
      compression = {
        type = "none";
      };
    };
  };
  systemd.services.atticd.serviceConfig.ReadWritePaths = "/nix-cache";

}
