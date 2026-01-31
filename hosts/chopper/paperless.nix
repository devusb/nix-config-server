{
  config,
  lib,
  caddyHelpers,
  ...
}:
{
  services.paperless = {
    enable = true;
    passwordFile = config.sops.secrets.paperless_admin.path;
    environmentFile = config.sops.secrets.paperless_config.path;
    settings = {
      "PAPERLESS_CSRF_TRUSTED_ORIGINS" =
        "https://paperless.devusb.us,https://paperless.chopper.devusb.us";
      "PAPERLESS_CORS_ALLOWED_HOSTS" = "https://paperless.devusb.us,https://paperless.chopper.devusb.us";
      "PAPERLESS_ALLOWED_HOSTS" = "paperless.devusb.us,paperless.chopper.devusb.us";
    };
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "paperless.${domain}" = helpers.mkVirtualHost config.services.paperless.port;
  };

  services.deploy-backup.backups.paperless = lib.mkIf config.services.deploy-backup.enable {
    files = [
      config.services.paperless.dataDir
    ];
  };
}
