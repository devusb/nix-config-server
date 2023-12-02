{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.jellyplex-watched;
in
{
  options.services.jellyplex-watched = with types; {
    enable = mkEnableOption (mdDoc "Sync between Jellyfin and Plex");
    package = mkPackageOption pkgs "jellyplex-watched" { };
    environmentFile = mkOption {
      type = nullOr path;
      default = null;
      example = "/run/secrets/jellyplex-watched";
    };
    settings = mkOption {
      type = types.submodule (settings: {
        freeformType = attrsOf str;
      });
      default = { };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.jellyplex-watched = {
      description = "jellyplex-watched";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        LOGFILE = "/run/jellyplex-watched/log.log";
        MARKFILE = "/run/jellyplex-watched/mark.log";
      };

      serviceConfig = {
        ExecStart = "${getExe cfg.package}";
        RuntimeDirectory = "jellyplex-watched";
        RuntimeDirectoryMode = "0700";
        DynamicUser = true;

        EnvironmentFile = [
          cfg.environmentFile
          (pkgs.writeText "jellyplex-watched-settings" (generators.toKeyValue { } cfg.settings))
        ];
      };
    };
  };
}
