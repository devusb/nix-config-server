{ pkgs, lib, config, ... }: {

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
  services.readarr = {
    enable = true;
    user = "media";
    group = "media";
    package = pkgs.readarr.overrideAttrs (old:
      let
        os = "linux";
        arch = "x64";
        version = "0.4.1.2648";
      in
      {
        inherit version;
        src = pkgs.fetchurl {
          url = "https://github.com/Readarr/Readarr/releases/download/v${version}/Readarr.develop.${version}.${os}-core-${arch}.tar.gz";
          hash = "sha256-oEdO9V9QLPXkZh+QUyVjlMY21iFT1p8i2DoPWpR3Qlg=";
        };
      });
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
