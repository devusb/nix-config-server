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
  ];
  wildcardDomain = "chopper.devusb.us";
  mkVirtualHost = port: {
    useACMEHost = wildcardDomain;
    extraConfig = ''
      reverse_proxy :${toString port}
    '';
  };
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
      ./fileshare.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.zfs.extraPools = [ "r2d2_0" ];
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;

  hardware.opengl = {
    enable = true;
  };

  networking.hostName = "chopper"; # Define your hostname.
  networking.hostId = "bf399afd";

  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

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
    virtualHosts = {
      "plex.${wildcardDomain}" = mkVirtualHost 32400;
      "sonarr.${wildcardDomain}" = mkVirtualHost 8989;
      "radarr.${wildcardDomain}" = mkVirtualHost 7878;
      "nzbget.${wildcardDomain}" = mkVirtualHost 6789;
      "syncthing.${wildcardDomain}" = mkVirtualHost 8384;
      "cockpit.${wildcardDomain}" = mkVirtualHost 9090;
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

