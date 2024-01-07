{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.go-simple-upload-server;
in
{
  options.services.go-simple-upload-server = with types; {
    enable = mkEnableOption (mdDoc "Simple HTTP server to save artifacts ");
    package = mkPackageOption pkgs "go-simple-upload-server" { };
    settings = mkOption {
      type = types.nullOr (types.attrsOf types.unspecified);
      default = null;
    };
    extraGroups = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
    };
    group = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
  };

  config =
    let
      settingsFile = pkgs.writeTextFile {
        name = "config.json";
        text = builtins.toJSON cfg.settings;
      };
    in
    mkIf cfg.enable {
      systemd.services.go-simple-upload-server = {
        description = "go-simple-upload-server";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          ExecStart = "${getExe cfg.package} -config ${settingsFile}";
          DynamicUser = true;
          ReadWritePaths = mkIf (cfg.settings != null && builtins.hasAttr "document_root" cfg.settings) "${cfg.settings.document_root}";
          SupplementaryGroups = mkIf (cfg.extraGroups != null) cfg.extraGroups;
          Group = mkIf (cfg.group != null) "${cfg.group}";
        };
      };
    };
}
