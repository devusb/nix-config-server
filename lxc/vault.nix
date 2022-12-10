{ lib, pkgs, config, modulesPath, ... }:
{

  system.stateVersion = "22.05";

  deployment = {
    targetHost = "192.168.20.103";
    targetPort = 22;
    targetUser = "root";
  };

  networking.hostName = "vault";

  services.tailscale-serve = {
    enable = true;
    port = 8200;
  };

  sops.secrets.vault_unseal = {
    sopsFile = ../secrets/vault-unseal.yaml;
  };
  services.vault = {
    enable = true;
    storageBackend = "raft";
    package = pkgs.vault-bin;
    extraConfig = ''
      cluster_addr = "http://127.0.0.1:8201"
      api_addr = "http://127.0.0.1:8200"
      disable_mlock = true
      ui = "true"
      seal "awskms" {
        region = "us-east-1"
      }
    '';
  };
  systemd.services.vault.serviceConfig.EnvironmentFile = config.sops.secrets.vault_unseal.path;

}
