{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.nomad-client;
in
{
  options = {
    services.nomad-client = {
      enable = mkEnableOption { };

      nomadPackage = mkPackageOption pkgs "nomad" { };
      consulPackage = mkPackageOption pkgs "consul" { };

      interface = mkOption {
        type = types.str;
        default = "tailscale0";
      };

      servers = mkOption {
        type = with types; listOf str;
        default = [ "gaia0" ];
      };

      vaultAddress = mkOption {
        type = types.str;
        default = "https://vault.springhare-egret.ts.net";
      };

      datacenter = mkOption {
        type = types.str;
        default = "dc1";
      };

    };
  };

  config = mkIf cfg.enable {

    # tailscale
    services.tailscale-autoconnect = {
      enable = true;
    };
    systemd.services.tailscaled.wantedBy = [
      "docker.service"
      "nomad.service"
      "consul.service"
    ];

    services.nomad = {
      enable = true;
      dropPrivileges = false;
      package = cfg.nomadPackage;

      settings = {
        datacenter = cfg.datacenter;
        bind_addr = ''{{ GetInterfaceIP "${cfg.interface}" }}'';
        client = {
          enabled = true;
          servers = cfg.servers;
          network_interface = cfg.interface;
        };
        vault = {
          enabled = true;
          address = cfg.vaultAddress;
        };
        plugin.docker = {
          config = {
            allow_privileged = true;
            volumes = {
              enabled = true;
            };
          };
        };
      };
    };

    services.consul = {
      enable = true;
      package = cfg.consulPackage;
      interface.bind = cfg.interface;
      extraConfig = {
        datacenter = cfg.datacenter;
        retry_join = cfg.servers;
        ports.grpc = 8502;
      };
    };

    services.rpcbind.enable = true;

  };
}
