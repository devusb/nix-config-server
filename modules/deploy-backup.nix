{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.deploy-backup;
  deployBackup =
    {
      name,
      filesList,
      url,
    }:
    pkgs.writeShellScriptBin "deployBackup" ''
      ${getExe pkgs.gnutar} cvf /tmp/${name}.tar.gz ${
        strings.concatMapStrings (x: " " + x) filesList
      } -I ${getExe' pkgs.gzip "gzip"}
      ${getExe pkgs.curl} -Ffile=@/tmp/${name}.tar.gz '${url}'
      rm /tmp/${name}.tar.gz
      ${getExe pkgs.logger} "${name} backup completed $(date)"
    '';
in
{
  options = {
    services.deploy-backup = {
      enable = mkEnableOption (lib.mdDoc "automatic backup deployment");

      backups = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              files = mkOption {
                type = types.listOf types.str;
                description = mdDoc "Files to back up";
              };

              schedule = mkOption {
                type = types.str;
                default = "Mon *-*-* 00:00:00 America/Chicago";
                description = mdDoc "Schedule string for how often to perform backup";
              };

              user = mkOption {
                type = types.str;
                default = "root";
                description = mdDoc "User to execute backup";
              };

              backupScript = mkOption {
                type = types.str;
                default = "";
                description = mdDoc "Script to gather files to be backed up";
              };
            };
          }
        );
        default = { };
      };

      url = mkOption {
        type = types.str;
        default = "https://backup.chopper.devusb.us/upload?token=59af2e561fc9f80a9bb9&overwrite=true";
        description = mdDoc "URL to send backup";
      };

    };
  };

  config = mkIf cfg.enable {
    systemd.timers = mapAttrs' (
      name: value:
      nameValuePair "backup-${name}" {
        description = "${name} backup";
        timerConfig = {
          OnCalendar = "${value.schedule}";
          Persistent = true;
        };
        wantedBy = [ "timers.target" ];
      }
    ) cfg.backups;

    systemd.services = mapAttrs' (
      name: value:
      nameValuePair "backup-${name}" {
        description = "${name} backup";
        serviceConfig = {
          Type = "oneshot";
          User = value.user;
        };
        script = "${value.backupScript}" + ''
          ${
            deployBackup {
              inherit name;
              filesList = value.files;
              url = cfg.url;
            }
          }/bin/deployBackup
        '';
      }
    ) cfg.backups;

  };
}
