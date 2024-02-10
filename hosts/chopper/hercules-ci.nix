{ pkgs, config, ... }: {
  sops.secrets.hercules_join.owner = "hercules-ci-agent";
  sops.secrets.hercules_secrets.owner = "hercules-ci-agent";
  services.hercules-ci-agent = {
    enable = true;
    settings = {
      clusterJoinTokenPath = config.sops.secrets.hercules_join.path;
      secretsJsonPath = config.sops.secrets.hercules_secrets.path;
      concurrentTasks = 3;
      binaryCachesPath = (pkgs.writeText "binary-caches.json" (builtins.toJSON { }));
    };
  };
}
