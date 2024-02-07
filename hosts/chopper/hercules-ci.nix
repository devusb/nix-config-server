{ pkgs, config, ... }: {
  sops.secrets.hercules_join.owner = "hercules-ci-agent";
  services.hercules-ci-agent = {
    enable = true;
    settings = {
      clusterJoinTokenPath = config.sops.secrets.hercules_join.path;
      concurrentTasks = 2;
      binaryCachesPath = (pkgs.writeText "binary-caches.json" (builtins.toJSON { }));
    };
  };
}
