{ pkgs, lib, config, ... }:
let
  backupPath = "/tmp/miniflux_db.tar";
in
{
  systemd.tmpfiles.settings."miniflux-sock"."/run/miniflux".d = {
    user = "miniflux";
    mode = "0755";
  };
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.miniflux_creds.path;
    config = {
      LISTEN_ADDR = "/run/miniflux/miniflux.sock";
      AUTH_PROXY_HEADER = "X-Pomerium-Claim-Email";
    };
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
