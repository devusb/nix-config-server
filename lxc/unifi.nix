{ lib, pkgs, config, modulesPath, ... }:
let
  deployedBackup = pkgs.deployBackup {
    backup_name = "unifi";
    backup_files_list = [
      ''"$(find "/var/lib/unifi/data/backup/autobackup" -path "*autobackup*unf*" -printf '%Ts\t%p\n' | sort -n | cut -f2 | tail -n 1)"''
    ];
  };
in
{

  system.stateVersion = "22.05";

  deployment = {
    targetHost = "192.168.20.105";
    targetPort = 22;
    targetUser = "root";
  };

  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 0 * * 1     root    ${deployedBackup}/bin/deployBackup"
    ];
  };

  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unifi6;
  };
}
