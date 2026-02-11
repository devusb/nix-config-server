{
  caddyHelpers,
  pkgs,
  ...
}:
{
  services.calibre-web-automated = {
    enable = true;
    package = pkgs.calibre-web-automated.overrideAttrs (old: {
      patches = old.patches ++ [
        (pkgs.fetchpatch {
          url = "https://github.com/crocodilestick/Calibre-Web-Automated/compare/main...devusb:Calibre-Web-Automated:jump-to-koreader.patch";
          hash = "sha256-kp48O2lVcG8+qQ222RfNbuqTIxJKzey4IzVyxN5rkqk=";
        })
      ];
    });
    listen.ip = "127.0.0.1";
    dataDir = "/var/lib/calibre-web";
    options.calibreLibrary = "/var/lib/calibre-web";
    options.enableBookConversion = true;
    options.enableBookUploading = true;
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "calibre.${domain}" = helpers.mkVirtualHost 8083;
  };

}
