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
  networking.firewall = {
    allowPing = false;
    allowedTCPPorts = [
      443
    ];
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

  sops.secrets.pomerium_secrets = {
    sopsFile = ../../images/pomerium/secrets.yaml;
  };
  services.pomerium = {
    enable = true;
    configFile = ../../images/pomerium/config.yaml;
    secretsFile = config.sops.secrets.pomerium_secrets.path;
  };
  services.postgresql = {
    enable = true;
    ensureUsers = [{
      name = "pomerium";
      ensureDBOwnership = true;
    }];
    ensureDatabases = [ "pomerium" ];
  };

  system.stateVersion = "23.11";
}
