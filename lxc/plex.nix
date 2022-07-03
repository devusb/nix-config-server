{ lib, pkgs, config, modulesPath, ... }: {
  imports = [
    ../template
  ];
  system.stateVersion = "22.05";

  deployment = {
    targetHost = "192.168.20.130";
    targetPort = 22;
    targetUser = "root";
    replaceUnknownProfiles = true;
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

  environment.systemPackages = with pkgs; [
    (deployBackup {
      backup_name = "plex";
      backup_files_list = [
        ''"$(find "/mnt/plex_data//Plex Media Server/Plug-in Support/Databases/" -path "*com.plexapp.plugins.library.db-2*" -printf '%Ts\t%p\n' | sort -n | cut -f2 | tail -n 1)"''
        ''"$(find "/mnt/plex_data//Plex Media Server/Plug-in Support/Databases/" -path "*com.plexapp.plugins.library.blobs.db-2*" -printf '%Ts\t%p\n' | sort -n | cut -f2 | tail -n 1)"''
      ];
    })
  ];

  services.plex = {
    enable = true;
    user = "media";
    group = "media";
    dataDir = "/mnt/plex_data";
    package = (pkgs.plex.override {
      plexRaw = pkgs.plexRaw.overrideAttrs (old: rec {
        version = "1.27.2.5929-a806c5905";
        src = pkgs.fetchurl {
          url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
          sha1 = "sha1-62uDZ6hn5uqPqLFwE0FTZsSaqco=";
        };
      });
    });
  };

}
