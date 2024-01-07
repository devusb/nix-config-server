{ pkgs, config, ... }: {
  services.jellyfin = {
    enable = true;
    user = "media";
    group = "media";
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
      PLEX_BASEURL = "http://localhost:32400";
      USER_MAPPING = ''{ "devusb": "mhelton" }'';
      LIBRARY_MAPPING = ''{ "Shows": "TV Shows" }'';
    };
  };

}
