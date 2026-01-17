{
  pkgs,
  lib,
  config,
  caddyHelpers,
  ...
}:
let
  backupPath = "/tmp/miniflux_db.tar";
in
{
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.miniflux_creds.path;
    config = {
      LISTEN_ADDR = "/run/miniflux/miniflux.sock";
      AUTH_PROXY_HEADER = "X-authentik-email";
      TRUSTED_REVERSE_PROXY_NETWORKS = "100.64.0.0/10,127.0.0.0/8,192.168.20.0/23";
    };
  };
  systemd.services.miniflux.serviceConfig.RuntimeDirectoryMode = lib.mkForce "0755";

  services.caddy.virtualHosts = with caddyHelpers; {
    "miniflux.${domain}" = helpers.mkSocketVirtualHost "/run/miniflux/miniflux.sock";
  };

  services.deploy-backup.backups.miniflux = lib.mkIf config.services.deploy-backup.enable {
    files = [
      backupPath
    ];
    backupScript = with pkgs; ''
      ${config.security.wrapperDir}/sudo -u postgres ${postgresql}/bin/pg_dump -d miniflux -F t -f ${backupPath}
    '';
  };
}
