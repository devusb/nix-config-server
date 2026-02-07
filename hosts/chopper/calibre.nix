{
  caddyHelpers,
  ...
}:
{
  services.calibre-web-automated = {
    enable = true;
    listen.ip = "127.0.0.1";
    dataDir = "calibre-web";
    options.calibreLibrary = "/var/lib/calibre-web";
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "calibre.${domain}" = helpers.mkVirtualHost 8083;
  };

}
