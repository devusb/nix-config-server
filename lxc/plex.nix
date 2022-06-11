{ lib, pkgs, config, modulesPath, ... }: {
  imports = [
    ../template
  ];
  system.stateVersion = "22.05";
  
  deployment = {
    targetHost = "192.168.20.51";
    targetPort = 22;
    targetUser = "root";
    replaceUnknownProfiles = true;
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
    linuxPackages.nvidia_x11_legacy470 
    (deployBackup { 
      backup_name = "plex-nix"; 
      backup_files_list = [ 
        ''"$(find "/var/lib/plex/Plex Media Server/Plug-in Support/Databases/" -path "*com.plexapp.plugins.library.db-2*" -printf '%Ts\t%p\n' | sort -n | cut -f2 | tail -n 1)"''
        ''"$(find "/var/lib/plex/Plex Media Server/Plug-in Support/Databases/" -path "*com.plexapp.plugins.library.blobs.db-2*" -printf '%Ts\t%p\n' | sort -n | cut -f2 | tail -n 1)"''
      ];
    })
  ];

  services.plex = {
    enable = true;
    user = "media";
    group = "media";
    package = (pkgs.plex.override {
      plexRaw = pkgs.plexRaw.overrideAttrs(old: rec {
        version = "1.26.2.5797-5bd057d2b";
        src = pkgs.fetchurl {
          url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
          sha256 = "sha256-TbjRItXTJPZXwiNV3RFzAAC/AiFqXd9JNM6QEdPF2CI=";
        };
      });
    }); 
  };

}
