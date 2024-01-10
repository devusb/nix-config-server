{ pkgs, lib, config, ... }:
let
  plexData = "/r2d2_0/media/plex-data";
in
{
  users.groups = {
    media.gid = 1002;
  };

  users.users.media = {
    isNormalUser = true;
    uid = 1002;
    group = "media";
  };

  services.plex = {
    enable = true;
    user = "media";
    group = "media";
    dataDir = plexData;
    package = pkgs.plexpass;
    openFirewall = true;
  };

  services.tautulli = {
    enable = true;
  };

  services.deploy-backup.backups.plex = lib.mkIf config.services.deploy-backup.enable {
    files = [
      ''"$(find "${plexData}/Plex Media Server/Plug-in Support/Databases/" -path "*com.plexapp.plugins.library.db-2*" -printf '%Ts\t%p\n' | sort -n | cut -f2 | tail -n 1)"''
      ''"$(find "${plexData}/Plex Media Server/Plug-in Support/Databases/" -path "*com.plexapp.plugins.library.blobs.db-2*" -printf '%Ts\t%p\n' | sort -n | cut -f2 | tail -n 1)"''
    ];
  };

  services.deploy-backup.backups.tautulli = lib.mkIf config.services.deploy-backup.enable {
    files = [
      "/var/lib/plexpy/config.ini"
      "/var/lib/plexpy/tautulli.db"
    ];
  };

}
