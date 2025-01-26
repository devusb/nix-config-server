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
    settings = {
      "PAPERLESS_ENABLE_HTTP_REMOTE_USER" = true;
      "PAPERLESS_HTTP_REMOTE_USER_HEADER_NAME" = "HTTP_X_POMERIUM_CLAIM_EMAIL";
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
