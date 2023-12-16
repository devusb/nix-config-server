{ lib, pkgs, config, modulesPath, ... }:
{

  system.stateVersion = "23.05";

  deployment = {
    targetHost = "192.168.20.107";
    targetPort = 22;
    targetUser = "root";
  };

  networking.hostName = "jellyfin";

  services.tailscale-serve = {
    enable = true;
    port = 8096;
  };

  hardware.opengl = {
    enable = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_470;

  users.groups = {
    media.gid = 1002;
  };

  users.users.media = {
    isNormalUser = true;
    uid = 1002;
    group = "media";
  };

  services.jellyfin = {
    enable = true;
    user = "media";
    group = "media";
  };

  sops.secrets.jellyplex_creds = {
    sopsFile = ../secrets/jellyplex-watched.yaml;
  };
  services.jellyplex-watched = {
    enable = true;
    package = pkgs.nix-config.jellyplex-watched;
    environmentFile = config.sops.secrets.jellyplex_creds.path;
    settings = {
      DRYRUN = "False";
      DEBUG = "True";
      SYNC_FROM_PLEX_TO_JELLYFIN = "True";
      SYNC_FROM_JELLYFIN_TO_PLEX = "True";
      SYNC_FROM_PLEX_TO_PLEX = "False";
      SYNC_FROM_JELLYFIN_TO_JELLYFIN = "False";
      JELLYFIN_BASEURL = "http://localhost:8096";
      PLEX_BASEURL = "https://plex.springhare-egret.ts.net";
      USER_MAPPING = ''{ "devusb": "mhelton" }'';
      LIBRARY_MAPPING = ''{ "Shows": "TV Shows" }'';
    };
  };

}