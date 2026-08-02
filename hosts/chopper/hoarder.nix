{
  config,
  caddyHelpers,
  pkgs,
  lib,
  ...
}:

{
  sops.secrets.hoarder = { };
  services.karakeep = {
    enable = true;
    extraEnvironment = {
      "NEXTAUTH_URL" = "https://hoarder.chopper.devusb.us";
      "NEXTAUTH_URL_INTERNAL" = "http://localhost:3000";
      "OAUTH_PROVIDER_NAME" = "authentik";
      "OAUTH_ALLOW_DANGEROUS_EMAIL_ACCOUNT_LINKING" = "true";
      "DISABLE_SIGNUPS" = "true";
      "DISABLE_PASSWORD_AUTH" = "true";
    };
    environmentFile = config.sops.secrets.hoarder.path;
  };
  services.meilisearch = {
    package = pkgs.meilisearch;
    settings = lib.mkForce (
      let
        stateDir = "/var/lib/meilisearch";
      in
      {
        http_addr = "${config.services.meilisearch.listenAddress}:${toString config.services.meilisearch.listenPort}";

        db_path = stateDir;
        dump_dir = "${stateDir}/dumps";
        snapshot_dir = "${stateDir}/snapshots";

        no_analytics = true;
        upgrade_db = true;
      }
    );
  };
  systemd.services.meilisearch.serviceConfig.ProcSubset = lib.mkForce "all";

  services.caddy.virtualHosts = with caddyHelpers; {
    "hoarder.${domain}" = helpers.mkVirtualHost 3000;
  };

  sops.secrets.hoarder_miniflux = { };
  services.hoarder-miniflux-webhook = {
    enable = true;
    environmentFile = config.sops.secrets.hoarder_miniflux.path;
    settings = {
      PORT = ":24234";
      HOARDER_API_URL = "http://localhost:3000";
    };
  };

  services.deploy-backup.backups.hoarder = {
    files = [
      "/var/lib/karakeep"
    ];
  };

}
