{ lib, pkgs, config, modulesPath, ... }:
let
  backupPath = "/tmp/atuin_db.tar";
  deployedBackup = pkgs.deployBackup {
    backup_name = "atuin";
    backup_files_list = [
      backupPath
    ];
  };
in
{

  system.stateVersion = "22.05";

  deployment = {
    targetHost = "192.168.20.102";
    targetPort = 22;
    targetUser = "root";
  };

  networking.hostName = "atuin";

  services.tailscale.package = pkgs.tailscale-unstable;

  services.atuin = {
    enable = true;
    host = "0.0.0.0";
  };

  services.caddy = {
    enable = true;
    extraConfig = ''
      ${config.networking.hostName}.springhare-egret.ts.net
      reverse_proxy :8888
    '';
  };

  services.cron = {
    enable = true;
    systemCronJobs = with pkgs; [
      "0 0 * * 1     root    ${sudo}/bin/sudo -u postgres ${postgresql}/bin/pg_dump -d atuin -F t -f ${backupPath} && ${deployedBackup}/bin/deployBackup"
    ];
  };

}
