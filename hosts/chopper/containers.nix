{ config, inputs, ... }:
{
  systemd.network.networks."19-containers" = {
    matchConfig.Name = "ve-*";
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

}
