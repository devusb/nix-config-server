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

  services.nomad = {
    enable = true;
    settings = {
      datacenter = "dc1";
      server = {
        enabled = true;
        bootstrap_expect = 1;
      };
      client.enabled = true;
    };
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

  services.caddy = {
    enable = true;
    extraConfig = ''
      ${config.networking.hostName}.springhare-egret.ts.net {
        reverse_proxy /* {
          to localhost:8080
          to gaia1:8080
        
          health_path     /ping
          health_port     8081
          health_interval 10s
          health_timeout  2s
          health_status   200
        }
      }
    '';
  };

}
