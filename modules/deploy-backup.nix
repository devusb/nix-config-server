{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.deployBackup;
  deployBackup = { backup_name, backup_files_list, backup_url }:
    pkgs.writeShellScriptBin "deployBackup" ''
      tar cvzf /tmp/${backup_name}.tar.gz ${strings.concatMapStrings (x: " " + x) backup_files_list}
      curl -Ffile=@/tmp/${backup_name}.tar.gz '${backup_url}'
      rm /tmp/${backup_name}.tar.gz
      logger "${backup_name} backup completed $(date)"
    '';
in
{
  options = {
    services.deployBackup = {
      enable = mkEnableOption (lib.mdDoc "automatic backup deployment");

      files = mkOption {
        type = types.listOf types.str;
        description = mdDoc "Files to back up";
      };

      name = mkOption {
        type = types.str;
        description = mdDoc "Name for backup archive";
      };

      frequency = mkOption {
        type = types.str;
        default = "0 0 * * 1";
        description = mdDoc "Cron string for how often to perform backup";
      };

      user = mkOption {
        type = types.str;
        default = "root";
        description = mdDoc "User to execute backup";
      };

      url = mkOption {
        type = types.str;
        default = "http://192.168.20.133:25478/upload?token=59af2e561fc9f80a9bb9";
        description = mdDoc "URL to send backup";
      };

    };
  };

  config =
    let
      deployedBackup = deployBackup { backup_name = cfg.name; backup_files_list = cfg.files; backup_url = cfg.url; };
    in
    mkIf cfg.enable {
      services.cron = {
        enable = true;
        systemCronJobs = [
          "${cfg.frequency}     ${cfg.user}    ${deployedBackup}/bin/deployBackup"
        ];
      };
    };
}
