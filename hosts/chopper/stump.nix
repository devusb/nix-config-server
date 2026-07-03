{ config, caddyHelpers, ... }: {
  services.stump = {
    enable = true;
    environmentFile = config.sops.secrets.stump.path;
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "stump.${domain}" = helpers.mkVirtualHost config.services.stump.port;
  };
}
