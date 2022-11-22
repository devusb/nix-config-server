{ lib, pkgs, config, modulesPath, ... }:
let
  deployedBackup = pkgs.deployBackup {
    backup_name = "arr";
    backup_files_list = [
      ''"$(find "/var/lib/sonarr/.config/NzbDrone/Backups/scheduled/" -path "*sonarr_backup*" -printf '%Ts\t%p\n' | sort -n | cut -f2 | tail -n 1)"''
      ''"$(find "/var/lib/radarr/.config/Radarr/Backups/scheduled/" -path "*radarr_backup*" -printf '%Ts\t%p\n' | sort -n | cut -f2 | tail -n 1)"''
      "/var/lib/nzbget/nzbget.conf"
    ];
  };
in
{

  system.stateVersion = "22.05";

  deployment = {
    targetHost = "192.168.20.101";
    targetPort = 22;
    targetUser = "root";
  };

  networking.hostName = "arr";

  users.groups = {
    media.gid = 1002;
  };

  users.users.media = {
    isNormalUser = true;
    uid = 1002;
    group = "media";
  };

  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 0 * * 1     root    ${deployedBackup}/bin/deployBackup"
    ];
  };

  environment.systemPackages = with pkgs; [
    unrar
    p7zip
    htop
  ];

  services.nzbget = {
    enable = true;
    user = "media";
    group = "media";
  };
  services.sonarr = {
    enable = true;
    user = "media";
    group = "media";
  };
  services.radarr = {
    enable = true;
    user = "media";
    group = "media";
  };

}
