{ config, lib, ... }: {
  sops.secrets.hercules_join.owner = "hercules-ci-agent";
  sops.secrets.hercules_secrets.owner = "hercules-ci-agent";
  sops.secrets.hercules_caches.owner = "hercules-ci-agent";
  services.hercules-ci-agent = {
    enable = true;
    settings = {
      clusterJoinTokenPath = config.sops.secrets.hercules_join.path;
      secretsJsonPath = config.sops.secrets.hercules_secrets.path;
      concurrentTasks = lib.mkDefault 8;
      binaryCachesPath = config.sops.secrets.hercules_caches.path;
    };
  };

  nix.settings = {
    cores = lib.mkDefault 4;
    max-jobs = lib.mkDefault 4;
  };
}
