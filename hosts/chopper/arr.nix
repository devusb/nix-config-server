{
  pkgs,
  lib,
  config,
  caddyHelpers,
  ...
}:
{

  services.nzbget = {
    enable = true;
    user = "media";
    group = "media";
    settings = {
      ControlPassword = "";
    };
  };
  services.sonarr = {
    enable = true;
    user = "media";
    group = "media";
    settings = {
      auth.method = "External";
    };
  };
  services.radarr = {
    enable = true;
    user = "media";
    group = "media";
    settings = {
      auth.method = "External";
    };
  };
  services.bazarr = {
    enable = true;
    user = "media";
    group = "media";
  };
  sops.secrets.sonarr_api_key.owner = "media";
  services.unpackerr = {
    enable = true;
    user = "media";
    group = "media";
    settings.sonarr = lib.singleton {
      url = "http://localhost:8989";
      api_key = "filepath:${config.sops.secrets.sonarr_api_key.path}";
      protocols = "usenet";
      paths = [ "/r2d2_0/media/nzbget/dst/Series" ];
    };
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "sonarr.${domain}" = helpers.mkVirtualHost 8989;
    "radarr.${domain}" = helpers.mkVirtualHost 7878;
    "bazarr.${domain}" = helpers.mkVirtualHost config.services.bazarr.listenPort;
    "nzbget.${domain}" = helpers.mkVirtualHost 6789;
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      whisper-asr-webservice = {
        image = "onerahmet/openai-whisper-asr-webservice:latest-gpu";
        ports = [
          "9000:9000"
        ];
        extraOptions = [
          "--cdi-spec-dir=/run/cdi"
          "--device=nvidia.com/gpu=all"
        ];
        environment = {
          ASR_MODEL = "base";
          ASR_ENGINE = "faster_whisper";
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [
    p7zip
    unrar
  ];

  services.deploy-backup.backups.arr = lib.mkIf config.services.deploy-backup.enable {
    files = [
      ''"$(find "/var/lib/sonarr/.config/NzbDrone/Backups/scheduled/" -path "*sonarr_backup*" -printf '%Ts\t%p\n' | sort -n | cut -f2 | tail -n 1)"''
      ''"$(find "/var/lib/radarr/.config/Radarr/Backups/scheduled/" -path "*radarr_backup*" -printf '%Ts\t%p\n' | sort -n | cut -f2 | tail -n 1)"''
      "/var/lib/nzbget/nzbget.conf"
    ];
  };

}
