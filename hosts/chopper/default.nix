# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

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
in
{
  imports =
    [
      ./hardware-configuration.nix
      ./disko-config.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "chopper"; # Define your hostname.
  networking.hostId = "bf399afd";

  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  networking.nat.enable = true;
  networking.nat.internalInterfaces = ["ve-+"];
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

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.auto-optimise-store = true;
    settings.trusted-users = [ "mhelton" ];
  };

  users.users.mhelton = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user.
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
  ];

  services.openssh.enable = true;

  security.acme = {
    acceptTerms = true;
    defaults.email = "devusb@devusb.us";
    certs = {
      "chopper.devusb.us" = {
        domain = "*.chopper.devusb.us";
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets.cloudflare.path;
      };
    };
  };

  system.stateVersion = "24.05"; # Did you read the comment?

}

