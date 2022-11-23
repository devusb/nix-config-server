{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.atuin;
in
{
  options = {
    services.atuin = {
      enable = mkEnableOption (mdDoc "Enable server for shell history sync with atuin.");

      package = mkOption {
        type = types.package;
        default = pkgs.atuin;
        defaultText = literalExpression "pkgs.atuin";
        description = "The package to use for atuin.";
      };

      openRegistration = mkOption {
        type = types.bool;
        default = true;
        defaultText = literalExpression "true";
        description = mdDoc "Allow new user registrations with the atuin server.";
      };

      path = mkOption {
        type = types.str;
        default = "";
        defaultText = literalExpression "";
        description = mdDoc "A path to prepend to all the routes of the server.";
      };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        defaultText = literalExpression "127.0.0.1";
        description = mdDoc "The host address the atuin server should listen on.";
      };

      port = mkOption {
        type = types.ints.u16;
        default = 8888;
        defaultText = literalExpression "8888";
        description = mdDoc "The port the atuin server should listen on.";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        defaultText = literalExpression "false";
        description = mdDoc "Open ports in the firewall for the atuin server.";
      };

    };
  };

  config = mkIf cfg.enable {

    # enable postgres to host atuin db
    services.postgresql = {
      enable = true;
      ensureUsers = [{
        name = "atuin";
        ensurePermissions = {
          "DATABASE atuin" = "ALL PRIVILEGES";
        };
      }];
      ensureDatabases = [ "atuin" ];
    };

    systemd.services.atuin = {
      description = "atuin server";
      after = [ "network.target" "postgresql.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/atuin server start";
        RuntimeDirectory = "atuin";
        RuntimeDirectoryMode = "0700";
        DynamicUser = true;
      };

      environment = {
        ATUIN_HOST = cfg.host;
        ATUIN_PORT = toString cfg.port;
        ATUIN_OPEN_REGISTRATION = if cfg.openRegistration then "true" else "false";
        ATUIN_DB_URI = "postgresql:///atuin";
        ATUIN_PATH = cfg.path;
        ATUIN_CONFIG_DIR = "/run/atuin";
      };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };

  };
}
