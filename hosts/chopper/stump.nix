{ config, caddyHelpers, ... }: {
  services.stump = {
    enable = true;
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "stump.${domain}" = helpers.mkVirtualHost config.services.stump.port;
  };
}
