{
  pkgs,
  config,
  caddyHelpers,
  ...
}:
{
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
  systemd.services.vault = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "vault.${domain}" = helpers.mkVirtualHost 8200;
  };

}
