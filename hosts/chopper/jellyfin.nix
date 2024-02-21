{ config, ... }: {
  services.jellyfin = {
    enable = true;
    user = "media";
    group = "media";
    openFirewall = true;
  };
  systemd.tmpfiles.settings."jellyfin-sock"."/run/jellyfin".d = {
    user = config.users.users.media.name;
    mode = "0755";
  };
  systemd.services.jellyfin.environment = {
    "JELLYFIN_kestrel__socketPermissions" = "0666";
    "JELLYFIN_kestrel__socketPath" = "/run/jellyfin/jellyfin.sock";
    "JELLYFIN_kestrel__socket" = "true";
  };

  services.jellyplex-watched = {
    enable = true;
    environmentFile = config.sops.secrets.jellyplex_creds.path;
    settings = {
      DRYRUN = "False";
      DEBUG = "False";
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
