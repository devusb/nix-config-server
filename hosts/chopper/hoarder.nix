# Auto-generated using compose2nix v0.3.2-pre.
{
  config,
  pkgs,
  lib,
  caddyHelpers,
  ...
}:

{
  # Enable container name DNS for non-default Podman networks.
  # https://github.com/NixOS/nixpkgs/issues/226365
  networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];

  virtualisation.oci-containers.backend = "podman";

  sops.secrets.hoarder = { };

  systemd.tmpfiles.settings."hoarder"."/var/lib/hoarder/hoarder".d = {
    mode = "0666";
  };
  systemd.tmpfiles.settings."meili"."/var/lib/hoarder/meili".d = {
    mode = "0666";
  };

  # Containers
  virtualisation.oci-containers.containers."hoarder-chrome" = {
    image = "gcr.io/zenika-hub/alpine-chrome:123";
    cmd = [
      "--no-sandbox"
      "--disable-gpu"
      "--disable-dev-shm-usage"
      "--remote-debugging-address=0.0.0.0"
      "--remote-debugging-port=9222"
      "--hide-scrollbars"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=chrome"
      "--network=hoarder_default"
    ];
  };
  systemd.services."podman-hoarder-chrome" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-hoarder_default.service"
    ];
    requires = [
      "podman-network-hoarder_default.service"
    ];
    partOf = [
      "podman-compose-hoarder-root.target"
    ];
    wantedBy = [
      "podman-compose-hoarder-root.target"
    ];
  };
  virtualisation.oci-containers.containers."hoarder-meilisearch" = {
    image = "getmeili/meilisearch:v1.11.1";
    environment = {
      "MEILI_NO_ANALYTICS" = "true";
    };
    environmentFiles = [
      config.sops.secrets.hoarder.path
    ];
    volumes = [
      "/var/lib/hoarder/meili:/meili_data:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=meilisearch"
      "--network=hoarder_default"
    ];
  };
  systemd.services."podman-hoarder-meilisearch" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-hoarder_default.service"
    ];
    requires = [
      "podman-network-hoarder_default.service"
    ];
    partOf = [
      "podman-compose-hoarder-root.target"
    ];
    wantedBy = [
      "podman-compose-hoarder-root.target"
    ];
  };
  virtualisation.oci-containers.containers."hoarder-web" = {
    image = "ghcr.io/hoarder-app/hoarder:0.21.0";
    environment = {
      "BROWSER_WEB_URL" = "http://chrome:9222";
      "DATA_DIR" = "/data";
      "MEILI_ADDR" = "http://meilisearch:7700";
      "NEXTAUTH_URL" = "https://hoarder.chopper.devusb.us";
      "NEXTAUTH_URL_INTERNAL" = "http://localhost:3000";
      "OAUTH_PROVIDER_NAME" = "authentik";
      "OAUTH_ALLOW_DANGEROUS_EMAIL_ACCOUNT_LINKING" = "true";
      "DISABLE_SIGNUPS" = "true";
      "DISABLE_PASSWORD_AUTH" = "true";
    };
    environmentFiles = [
      config.sops.secrets.hoarder.path
    ];
    volumes = [
      "/var/lib/hoarder/hoarder:/data:rw"
    ];
    ports = [
      "3000:3000/tcp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=web"
      "--network=hoarder_default"
    ];
  };
  systemd.services."podman-hoarder-web" = {
    serviceConfig = {
      Restart = lib.mkOverride 90 "always";
    };
    after = [
      "podman-network-hoarder_default.service"
    ];
    requires = [
      "podman-network-hoarder_default.service"
    ];
    partOf = [
      "podman-compose-hoarder-root.target"
    ];
    wantedBy = [
      "podman-compose-hoarder-root.target"
    ];
  };

  # Networks
  systemd.services."podman-network-hoarder_default" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "podman network rm -f hoarder_default";
    };
    script = ''
      podman network inspect hoarder_default || podman network create hoarder_default
    '';
    partOf = [ "podman-compose-hoarder-root.target" ];
    wantedBy = [ "podman-compose-hoarder-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."podman-compose-hoarder-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };

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
      "/var/lib/hoarder"
    ];
  };

}
