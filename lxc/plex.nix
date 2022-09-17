{ lib, pkgs, config, modulesPath, ... }:
let
  plexData = "/mnt/plex_data";
  deployedBackup = pkgs.deployBackup {
    backup_name = "plex";
    backup_files_list = [
      ''"$(find "${plexData}/Plex Media Server/Plug-in Support/Databases/" -path "*com.plexapp.plugins.library.db-2*" -printf '%Ts\t%p\n' | sort -n | cut -f2 | tail -n 1)"''
      ''"$(find "${plexData}/Plex Media Server/Plug-in Support/Databases/" -path "*com.plexapp.plugins.library.blobs.db-2*" -printf '%Ts\t%p\n' | sort -n | cut -f2 | tail -n 1)"''
    ];
  };
in
{

  system.stateVersion = "22.05";

  deployment = {
    targetHost = "192.168.20.130";
    targetPort = 22;
    targetUser = "root";
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

  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 0 * * 1     root    ${deployedBackup}/bin/deployBackup"
    ];
  };

  services.plex = {
    enable = true;
    user = "media";
    group = "media";
    dataDir = plexData;
    package = (pkgs.plex.override {
      plexRaw = pkgs.plexRaw.overrideAttrs (old: rec {
        version = "1.28.2.6106-44a5bbd28";
        src = pkgs.fetchurl {
          url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
          sha256 = "sha256-cJf15SLO2PNS8Okhod4/lftf987NPcxX8lX5sxUGIEY=";
        };
      });
    });
  };

  services.promtail = with lib; {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9080;
        grpc_listen_port = 0;
      };
      clients = singleton { url = "http://docker:3100/loki/api/v1/push"; };
      scrape_configs = singleton {
        job_name = "plex-journal";
        journal = {
          json = true;
          max_age = "12h";
          path = "/var/log/journal";
          labels = {
            job = "plex-journal";
          };
        };
        relabel_configs = singleton {
          source_labels = singleton "__journal__systemd_unit";
          target_label = "unit";
        };
      };
    };
  };

}
