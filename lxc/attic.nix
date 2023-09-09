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
        nar-size-threshold = 131072;
        min-size = 65536;
        avg-size = 131072;
        max-size = 262144;
      };
      database.url = "postgresql:///attic?host=/run/postgresql";
      garbage-collection.interval = "14 days";
    };
  };
  systemd.services.atticd.serviceConfig.ReadWritePaths = "/nix-cache";

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "attic" ];
    ensureUsers = [{
      name = "atticd";
      ensurePermissions = {
        "DATABASE attic" = "ALL PRIVILEGES";
      };
    }];
  };

}
