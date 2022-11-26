{ lib, pkgs, config, modulesPath, ... }:
{

  deployment = {
    targetHost = "192.168.20.138";
    targetPort = 22;
    targetUser = "mhelton";
  };

  networking.hostName = "gaia0";

  # tailscale
  services.tailscale-autoconnect = {
    enable = true;
    extraTailscaleArgs = [ "--operator=caddy" ];
  };

  sops.secrets.nomad = {
    sopsFile = ../secrets/nomad.yaml;
  };
  services.nomad = {
    enable = true;
    settings = {
      datacenter = "dc1";
      server = {
        enabled = true;
        bootstrap_expect = 1;
      };
      client = {
        enabled = true;
        network_interface = "tailscale0";
      };
      vault = {
        enabled = true;
        address = "https://vault.springhare-egret.ts.net";
        create_from_role = "nomad-cluster";
      };
    };
  };
  systemd.services.nomad.serviceConfig = {
    EnvironmentFile = config.sops.secrets.nomad.path;
  };

  services.consul = {
    enable = true;
    interface.bind = "tailscale0";
    webUi = true;
    extraConfig = {
      datacenter = "dc1";
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
    package = pkgs.caddy-cloudflare;
    extraConfig = ''
      *.gaia.devusb.us {
        tls {
          dns cloudflare {env.CF_API_TOKEN}
        }

        @nomad host nomad.gaia.devusb.us
        handle @nomad {
          reverse_proxy localhost:4646
        }

        @consul host consul.gaia.devusb.us
        handle @consul {
          reverse_proxy localhost:8500
        }

        @traefik host traefik.gaia.devusb.us
        handle @traefik {
          reverse_proxy localhost:8081
        }

        reverse_proxy * {
          dynamic a {
            name traefik.service.dc1.consul
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

}
