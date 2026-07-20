{ ... }:
{
  virtualisation.oci-containers = {
    backend = "podman";
    containers.jellyswarm = {
      volumes = [
        "/var/lib/jellyswarm:/app/data"
      ];
      ports = [
        "127.0.0.1:3000:3000"
      ];
      image = "ghcr.io/llukas22/jellyswarrm:0.2";
    };
  };

  services.nginx.virtualHosts."jellyfin.devusb.us" = {
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;
    # extraConfig = cloudflareOriginConfig;
    locations."/" = {
      proxyPass = "http://localhost:3000";
      extraConfig = ''
        proxy_ssl_server_name on;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade_keepalive;
      '';
      recommendedProxySettings = false;
    };
  };
}
