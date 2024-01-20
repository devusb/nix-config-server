{ inputs, config, lib, pkgs, ... }:
let
  secrets = [
    "ts_key"
    "jellyplex_creds"
    "miniflux_creds"
    "couchdb_admin"
    "vault_unseal"
    "attic_secret"
    "cloudflare"
    "pushover"
    "frigate"
  ];
  wildcardDomain = "chopper.devusb.us";
  caddy-helpers = import ../../lib/caddy-helpers.nix { inherit wildcardDomain; };
in
{
  imports =
    [
      ./hardware-configuration.nix
      ./disko-config.nix
      ../common
      ./containers.nix
      ./plex.nix
      ./arr.nix
      ./jellyfin.nix
      ./fileshare.nix
      ./miniflux.nix
      ./backup.nix
      ./vault.nix
      ./monitoring.nix
      ./unifi.nix
      ./hass.nix
      ./frigate.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [
    "pcie_port_pm=off"
    "pcie_aspm.policy=performance"
  ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  boot.zfs.extraPools = [ "r2d2_0" ];
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  hardware.opengl = {
    enable = true;
  };

  networking.hostName = "chopper"; # Define your hostname.
  networking.hostId = "bf399afd";

  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.
  networking.networkmanager.unmanaged = [
    "enp10s0u9u3c2"
    "tailcale0"
  ];

  networking.nat.enable = true;
  networking.nat.internalInterfaces = [ "ve-+" ];
  networking.nat.externalInterface = "enp4s0";

  sops = {
    defaultSopsFile = ../../secrets/default.yaml;
    secrets = lib.genAttrs secrets (_: { });
  };

  # tailscale
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    extraUpFlags = [ "--advertise-exit-node" "--ssh" ];
    authKeyFile = config.sops.secrets.ts_key.path;
  };

  # Set your time zone.
  time.timeZone = "US/Central";

  users.users = {
    mhelton = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" "media" ];
    };
    ilona = {
      isNormalUser = true;
      home = "/r2d2_0/homes/ilona";
      uid = 1102;
    };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  environment.systemPackages = with pkgs; [
    wget
    neovim
    curl
    git
    bottom
  ];

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

  services.openssh.enable = true;

  security.acme = {
    acceptTerms = true;
    defaults.email = "devusb@devusb.us";
    certs = {
      "${wildcardDomain}" = {
        domain = "*.${wildcardDomain}";
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets.cloudflare.path;
      };
    };
  };

  services.caddy = {
    enable = true;
    virtualHosts = with caddy-helpers; {
      "plex.${wildcardDomain}" = mkVirtualHost 32400;
      "sonarr.${wildcardDomain}" = mkVirtualHost 8989;
      "radarr.${wildcardDomain}" = mkVirtualHost 7878;
      "nzbget.${wildcardDomain}" = mkVirtualHost 6789;
      "syncthing.${wildcardDomain}" = mkVirtualHost 8384;
      "cockpit.${wildcardDomain}" = mkVirtualHost 9090;
      "miniflux.${wildcardDomain}" = mkSocketVirtualHost "/run/miniflux/miniflux.sock";
      "jellyfin.${wildcardDomain}" = mkSocketVirtualHost "/run/jellyfin/jellyfin.sock";
      "tautulli.${wildcardDomain}" = mkVirtualHost config.services.tautulli.port;
      "backup.${wildcardDomain}" = mkVirtualHost 8081;
      "vault.${wildcardDomain}" = mkVirtualHost 8200;
      "prometheus.${wildcardDomain}" = mkVirtualHost config.services.prometheus.port;
      "unifi.${wildcardDomain}" = mkHttpsVirtualHost 8443;
      "loki.${wildcardDomain}" = mkVirtualHost 3100;
      "grafana.${wildcardDomain}" = mkSocketVirtualHost "/run/grafana/grafana.sock";
      "pingshutdown.${wildcardDomain}" = mkVirtualHost 9081;
      "frigate.${wildcardDomain}" = mkSocketVirtualHost "/run/nginx/frigate.sock";
      "hass.${wildcardDomain}" = mkVirtualHost 8123;
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

