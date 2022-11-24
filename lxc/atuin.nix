{ lib, pkgs, config, modulesPath, ... }:
let
  backupPath = "/tmp/atuin_db.tar";
in
{

  system.stateVersion = "22.05";

  deployment = {
    targetHost = "192.168.20.102";
    targetPort = 22;
    targetUser = "root";
  };

  networking.hostName = "atuin";

  services.tailscale-serve = {
    enable = true;
    package = pkgs.tailscale-unstable;
    port = 8888;
    funnel = true;
  };

  services.atuin = {
    enable = true;
    host = "0.0.0.0";
    openRegistration = false;
  };

  services.deployBackup = {
    enable = true;
    name = "atuin";
    files = [
      backupPath
    ];
  };

  services.cron = {
    enable = true;
    systemCronJobs = with pkgs; [
      "0 23 * * 0     root    ${sudo}/bin/sudo -u postgres ${postgresql}/bin/pg_dump -d atuin -F t -f ${backupPath}"
    ];
  };

}
