args@{
  config,
  lib,
  pkgs,
  ...
}:
let
  secrets = [
    "ts_key"
    "jellyplex_creds"
    "miniflux_creds"
    "couchdb_admin"
    "vault_unseal"
    "attic_secret"
    "attic_token"
    "cloudflare"
    "pushover"
    "mosquitto"
    "paperless_admin"
    "buildbot_github_app_secret_key"
    "buildbot_github_oauth_secret"
    "buildbot_github_webhook_secret"
    "buildbot_nix_worker_password"
    "buildbot_nix_workers"
  ];
  domain = "chopper.devusb.us";
  caddyHelpers = import ../../lib/caddy-helpers.nix { inherit domain; };

  importList = [
    ./hardware-configuration.nix
    ./disko-config.nix
    ../common
    ./containers.nix
    ./virtualisation.nix
    ./plex.nix
    ./arr.nix
    ./jellyfin.nix
    ./fileshare.nix
    ./miniflux.nix
    ./backup.nix
    ./vault.nix
    ./monitoring.nix
    ./unifi.nix
    ./homeassistant.nix
    ../common/builder.nix
    ./paperless.nix
    ./glance.nix
    ./buildbot.nix
    ./calibre.nix
    ./hoarder.nix
  ];
in
{
  imports = builtins.map (path: import path (args // { inherit caddyHelpers; })) importList;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [
    "pcie_port_pm=off"
    "pcie_aspm.policy=performance"
  ];

  boot.zfs.extraPools = [ "r2d2_0" ];
  services.zfs.autoScrub = {
    enable = true;
    interval = "*-*-01,15 00:00:00";
  };
  services.zfs.trim.enable = true;

  nix.gc.dates = "monthly";

  hardware.graphics = {
    enable = true;
  };

  networking.hostName = "chopper"; # Define your hostname.
  networking.hostId = "bf399afd";

  networking.useNetworkd = true;
  systemd.network.networks."18-ipmi" = {
    matchConfig.Name = "enp11s0u9u3c2";
    linkConfig.Unmanaged = true;
  };

  networking.nat.enable = true;
  networking.nat.internalInterfaces = [ "ve-+" ];
  networking.nat.externalInterface = "enp5s0";

  sops = {
    defaultSopsFile = ../../secrets/default.yaml;
    secrets = lib.genAttrs secrets (_: { });
  };

  # tailscale
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--advertise-exit-node"
      "--ssh"
    ];
    authKeyFile = config.sops.secrets.ts_key.path;
  };

  # Set your time zone.
  time.timeZone = "US/Central";

  users.users = {
    mhelton = {
      extraGroups = [ "media" ];
    };
    ilona = {
      isNormalUser = true;
      home = "/r2d2_0/homes/ilona";
      uid = 1102;
    };
  };

  services.pingshutdown = {
    enable = true;
    environmentFile = config.sops.secrets.pushover.path;
    settings = {
      PINGSHUTDOWN_DELAY = "10m";
      PINGSHUTDOWN_TARGET = "192.168.20.1";
      PINGSHUTDOWN_NOTIFICATION = "true";
      PINGSHUTDOWN_DRYRUN = "false";
      PINGSHUTDOWN_STATUSPORT = "9081";
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "devusb@devusb.us";
    certs = {
      "${domain}" = {
        domain = "*.${domain}";
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets.cloudflare.path;
      };
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts = with caddyHelpers; {
      "cockpit.${domain}" = helpers.mkVirtualHost 9090;
      "pingshutdown.${domain}" = helpers.mkVirtualHost 9081;
    };
  };

  services.cockpit = {
    enable = true;
    settings = {
      WebService = {
        Origins = "https://cockpit.chopper.devusb.us";
      };
    };
  };

  system.stateVersion = "24.05"; # Did you read the comment?

}
