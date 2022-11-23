{ lib, pkgs, config, modulesPath, ... }:
let pomeriumConfig = pkgs.writeText "config.yaml" (builtins.readFile ./pomerium/config.yaml);
in
{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  # system
  deployment = {
    targetHost = "34.195.111.112";
    targetPort = 22;
    targetUser = "root";
  };
  system.stateVersion = "22.05";
  environment.systemPackages = with pkgs; [
    micro
    wget
    curl
    htop
  ];

  # networking
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedTCPPorts = [ 80 443 ];
  };
  networking.hostName = "aws-proxy";
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.enableIPv6 = true;

  # monitoring
  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = [ "systemd" "netstat" ];
    };
  };
  services.promtail = with lib; {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9080;
        grpc_listen_port = 0;
      };
      clients = singleton { url = "http://docker:3100/loki/api/v1/push"; };
      scrape_configs = singleton {
        job_name = "aws_proxy-journal";
        journal = {
          json = true;
          max_age = "12h";
          path = "/var/log/journal";
          labels = {
            job = "aws_proxy-journal";
          };
        };
        relabel_configs = singleton {
          source_labels = singleton "__journal__systemd_unit";
          target_label = "unit";
        };
      };
    };
  };

  # pomerium
  sops.secrets.pomerium_secrets = {
    sopsFile = ./secrets.yaml;
  };
  services.pomerium = {
    enable = true;
    configFile = pomeriumConfig;
    secretsFile = config.sops.secrets.pomerium_secrets.path;
  };
  services.redis = {
    enable = true;
  };

}
