{
  caddyHelpers,
  ...
}:
{
  virtualisation.oci-containers.containers.calibre-web-automated = {
    image = "crocodilestick/calibre-web-automated:v4.0.2";
    environment = {
      NETWORK_SHARE_MODE = "false";
      TZ = "US/Central";
    };
    volumes = [
      "/var/lib/calibre-web:/config"
      "/var/lib/calibre-web:/calibre-library"
      "/r2d2_0/media/Books:/r2d2_0/media/Books"
    ];
    ports = [
      "8083:8083"
    ];
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "calibre.${domain}" = helpers.mkVirtualHost 8083;
  };

}
