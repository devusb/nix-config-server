{ modulesPath, config, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ../common
    ./disk-config.nix
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

  system.stateVersion = "23.11";
}
