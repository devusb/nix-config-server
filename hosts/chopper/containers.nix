{ config, inputs, ... }: {
  containers.obsidian = {
    enableTun = true;
    privateNetwork = true;
    hostAddress = "10.10.100.1";
    localAddress = "10.10.100.2";
    restartIfChanged = true;
    autoStart = true;
    bindMounts = {
      "${config.sops.secrets.ts_key.path}".isReadOnly = true;
      "${config.sops.secrets.couchdb_admin.path}".isReadOnly = true;
      "/var/lib/couchdb".isReadOnly = false;
    };
    config = import ./obsidian.nix;
  };
  systemd.network.networks."19-obsidian" = {
    matchConfig.Name = "ve-obsidian";
    linkConfig.Unmanaged = true;
  };

  containers.attic = {
    specialArgs = {
      inherit inputs;
    };
    enableTun = true;
    privateNetwork = true;
    hostAddress = "10.10.100.3";
    localAddress = "10.10.100.4";
    restartIfChanged = true;
    autoStart = true;
    bindMounts = {
      "${config.sops.secrets.ts_key.path}".isReadOnly = true;
      "${config.sops.secrets.attic_secret.path}".isReadOnly = true;
      nix-cache = {
        hostPath = "/r2d2_0/nix-cache";
        mountPoint = "/nix-cache";
        isReadOnly = false;
      };
    };
    config = import ./attic.nix;
  };
  systemd.network.networks."19-attic" = {
    matchConfig.Name = "ve-attic";
    linkConfig.Unmanaged = true;
  };

  containers.atuin = {
    enableTun = true;
    privateNetwork = true;
    hostAddress = "10.10.100.5";
    localAddress = "10.10.100.6";
    restartIfChanged = true;
    autoStart = true;
    bindMounts = {
      "${config.sops.secrets.ts_key.path}".isReadOnly = true;
    };
    config = import ./atuin.nix;
  };
  systemd.network.networks."19-atuin" = {
    matchConfig.Name = "ve-atuin";
    linkConfig.Unmanaged = true;
  };

}
