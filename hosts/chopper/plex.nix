{ pkgs, ... }:
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

}
