{
  config,
  caddyHelpers,
  pkgs,
  ...
}:
{
  services.stump = {
    enable = true;
    environmentFile = config.sops.secrets.stump.path;
  };

  environment.systemPackages = [ pkgs.stump ];

  services.caddy.virtualHosts = with caddyHelpers; {
    "stump.${domain}" = helpers.mkVirtualHost config.services.stump.port;
  };
}
