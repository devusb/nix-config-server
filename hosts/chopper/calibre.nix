{
  config,
  caddyHelpers,
  wildcardDomain,
  ...
}:
{
  services.calibre-web = {
    enable = true;
    listen.ip = "127.0.0.1";
    options = {
      enableBookUploading = true;
      enableBookConversion = true;
      reverseProxyAuth = {
        enable = true;
        header = "X-Pomerium-Claim-Email";
      };
    };
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "calibre.${wildcardDomain}" = mkVirtualHost config.services.calibre-web.listen.port;
  };

}
