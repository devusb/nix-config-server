{ lib, pkgs, config, modulesPath, ... }:
let
  backupPath = "/tmp/miniflux_db.tar";
in
{

  system.stateVersion = "22.05";

  deployment = {
    targetHost = "192.168.20.100";
    targetPort = 22;
    targetUser = "root";
  };

  networking.hostName = "miniflux";

  services.tailscale-serve = {
    enable = true;
    port = 8080;
  };

  sops.secrets.admin_creds = {
    sopsFile = ../secrets/miniflux.yaml;
  };
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.admin_creds.path;
    config = {
      LISTEN_ADDR = "0.0.0.0:8080";
      AUTH_PROXY_HEADER = "X-Pomerium-Claim-Email";
    };
  };

  services.deployBackup = {
    enable = true;
    name = "miniflux";
    files = [
      backupPath
    ];
  };

  services.cron = {
    enable = true;
    systemCronJobs = with pkgs; [
      "0 23 * * 0     root    ${sudo}/bin/sudo -u postgres ${postgresql}/bin/pg_dump -d miniflux -F t -f ${backupPath}"
    ];
  };

}
