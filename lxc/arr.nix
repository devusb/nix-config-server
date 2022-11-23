{ lib, pkgs, config, modulesPath, ... }:
{

  system.stateVersion = "22.05";

  services.tailscale-autoconnect.enable = true;

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

  services.deployBackup = {
    enable = true;
    name = "arr";
    files = [
      ''"$(find "/var/lib/sonarr/.config/NzbDrone/Backups/scheduled/" -path "*sonarr_backup*" -printf '%Ts\t%p\n' | sort -n | cut -f2 | tail -n 1)"''
      ''"$(find "/var/lib/radarr/.config/Radarr/Backups/scheduled/" -path "*radarr_backup*" -printf '%Ts\t%p\n' | sort -n | cut -f2 | tail -n 1)"''
      "/var/lib/nzbget/nzbget.conf"
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
