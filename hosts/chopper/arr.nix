{
  pkgs,
  lib,
  config,
  caddyHelpers,
  wildcardDomain,
  ...
}:
{

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
  services.bazarr = {
    enable = true;
    user = "media";
    group = "media";
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "sonarr.${wildcardDomain}" = mkVirtualHost 8989;
    "radarr.${wildcardDomain}" = mkVirtualHost 7878;
    "bazarr.${wildcardDomain}" = mkVirtualHost config.services.bazarr.listenPort;
    "nzbget.${wildcardDomain}" = mkVirtualHost 6789;
  };

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      whisper-asr-webservice = {
        image = "onerahmet/openai-whisper-asr-webservice:latest";
        ports = [
          "9000:9000"
        ];
        environment = {
          ASR_MODEL = "small";
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
