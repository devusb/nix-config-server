{ inputs, ... }: {
  imports = [
    ../../modules/tailscale-serve.nix
    inputs.attic.nixosModules.atticd
  ];
  networking.hostName = "attic";
  services.tailscale-serve = {
    enable = true;
    port = 8080;
    funnel = true;
    authKeyFile = "/run/secrets/ts_key";
  };

  services.atticd = {
    enable = true;
    credentialsFile = "/run/secrets/attic_secret";
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
      database.url = "postgresql:///atticd?host=/run/postgresql";
      garbage-collection.interval = "14 days";
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "atticd" ];
    ensureUsers = [{
      name = "atticd";
      ensureDBOwnership = true;
    }];
  };

  system.stateVersion = "24.05";
}
