{ pkgs, config, ... }: {
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
