{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.nomad-server;
in
{
  options = {
    services.nomad-server = {
      enable = mkEnableOption { };

      nomadPackage = mkPackageOption pkgs "nomad" { };
      consulPackage = mkPackageOption pkgs "consul" { };
      caddyPackage = mkPackageOption pkgs "caddy-cloudflare" { };

      interface = mkOption {
        type = types.str;
        default = "tailscale0";
      };

      vaultAddress = mkOption {
        type = types.str;
        default = "https://vault.springhare-egret.ts.net";
      };

      domain = mkOption {
        type = types.str;
        default = "gaia.devusb.us";
      };

      datacenter = mkOption {
        type = types.str;
        default = "dc1";
      };

    };
  };

  config = mkIf cfg.enable {

    sops.secrets.nomad = {
      sopsFile = ../secrets/nomad.yaml;
    };
    services.nomad = {
      enable = true;
      dropPrivileges = false;
      package = cfg.nomadPackage;

      settings = {
        datacenter = cfg.datacenter;
        bind_addr = "0.0.0.0";
        advertise = {
          http = "127.0.0.1";
          serf = ''{{ GetInterfaceIP "${cfg.interface}" }}'';
          rpc = ''{{ GetInterfaceIP "${cfg.interface}" }}'';
        };
        server = {
          enabled = true;
          bootstrap_expect = 1;
        };
        client = {
          enabled = true;
          network_interface = cfg.interface;
        };
        vault = {
          enabled = true;
          address = cfg.vaultAddress;
          create_from_role = "nomad-cluster";
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
    systemd.services.nomad.serviceConfig = {
      EnvironmentFile = config.sops.secrets.nomad.path;
    };

    services.rpcbind.enable = true;

    services.consul = {
      enable = true;
      package = cfg.consulPackage;
      interface.bind = cfg.interface;
      webUi = true;
      extraConfig = {
        datacenter = cfg.datacenter;
        client_addr = "0.0.0.0";
        server = true;
        bootstrap_expect = 1;
        connect.enabled = true;
      };
    };


    sops.secrets.cloudflare = {
      sopsFile = ../secrets/cloudflare.yaml;
    };
    services.caddy = {
      enable = true;
      package = cfg.caddyPackage;
      extraConfig = ''
        *.${cfg.domain} {
          tls {
            dns cloudflare {env.CF_API_TOKEN}
          }

          @nomad host nomad.${cfg.domain}
          handle @nomad {
            reverse_proxy localhost:4646
          }

          @consul host consul.${cfg.domain}
          handle @consul {
            reverse_proxy localhost:8500
          }

          @traefik host traefik.${cfg.domain}
          handle @traefik {
            reverse_proxy localhost:8081
          }

          reverse_proxy * {
            dynamic a {
              name traefik.service.${cfg.datacenter}.consul
              port 8080
              resolvers localhost:8600
            }
          }
        }
      '';
    };
    systemd.services.caddy.serviceConfig = {
      EnvironmentFile = config.sops.secrets.cloudflare.path;
      AmbientCapabilities = "CAP_NET_BIND_SERVICE";
      ProtectSystem = "full";
      PrivateTmp = "true";
      LimitNPROC = "512";
      LimitNOFILE = "1048576";
      TimeoutStopSec = "5s";
    };

  };
}
