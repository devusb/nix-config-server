{ config, caddyHelpers, ... }:
{
  services.changedetection-io = {
    enable = true;
    behindProxy = true;
    playwrightSupport = true;
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "changedetection.${domain}" = helpers.mkVirtualHost config.services.changedetection-io.port;
  };
}
