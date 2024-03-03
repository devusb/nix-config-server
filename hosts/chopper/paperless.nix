{ config, ... }: {
  services.paperless = {
    enable = true;
    passwordFile = config.sops.secrets.paperless_admin.path;
    extraConfig = {
      "PAPERLESS_ENABLE_HTTP_REMOTE_USER" = true;
      "PAPERLESS_HTTP_REMOTE_USER_HEADER_NAME" = "HTTP_X_POMERIUM_CLAIM_EMAIL";
      "PAPERLESS_CSRF_TRUSTED_ORIGINS" = "https://paperless.devusb.us,https://paperless.chopper.devusb.us";
      "PAPERLESS_CORS_ALLOWED_HOSTS" = "https://paperless.devusb.us,https://paperless.chopper.devusb.us";
      "PAPERLESS_ALLOWED_HOSTS" = "paperless.devusb.us,paperless.chopper.devusb.us";
    };
  };
}
