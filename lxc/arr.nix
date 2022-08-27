{ lib, pkgs, config, modulesPath, ... }:
{

  system.stateVersion = "22.05";

  deployment = {
    targetHost = "192.168.20.101";
    targetPort = 22;
    targetUser = "root";
  };

  users.groups = {
    media.gid = 1002;
  };

  users.users.media = {
    isNormalUser = true;
    uid = 1002;
    group = "media";
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
