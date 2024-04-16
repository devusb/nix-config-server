{ modulesPath, config, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./hardware-configuration.nix
    ../common
    ./disko-config.nix
    ../common/hercules-ci.nix
  ];

  deployment = {
    targetHost = "the-doctor";
    targetPort = 22;
    targetUser = "mhelton";
  };

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking.hostName = "the-doctor";
  networking.firewall = {
    allowPing = false;
  };
  services.openssh.openFirewall = false;

  # tailscale
  sops.secrets.ts_key = {
    sopsFile = ../../secrets/default.yaml;
  };
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    extraUpFlags = [ "--advertise-exit-node" "--ssh" ];
    authKeyFile = config.sops.secrets.ts_key.path;
  };

  services.hercules-ci-agent.concurrentTasks = 4;

  system.stateVersion = "24.05";
}
