{
  config,
  pkgs,
  lib,
  ...
}:
let
  wildcardDomain = "spdr.devusb.us";
  caddy-helpers = import ../../lib/caddy-helpers.nix { inherit wildcardDomain; };
in
{
  imports = [
    ../common
    ./hardware-configuration.nix
    ./disko-config.nix
  ];

  deployment = {
    targetHost = "spdr";
    targetPort = 22;
    targetUser = "mhelton";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 10;

  # zfs
  boot.supportedFilesystems = [ "zfs" ];
  networking.hostId = "9141a4f1";

  services.zfs.autoScrub = {
    enable = true;
    interval = "*-*-01,15 00:00:00";
  };
  services.zfs.trim.enable = true;

  # erase your darlings
  boot.initrd.postResumeCommands = lib.mkAfter ''
    zfs rollback -r rpool/local/root@blank
  '';
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/nixos"
      "/var/lib/tailscale"
      "/var/lib/plex"
      "/var/lib/jellyfin"
      "/var/lib/acme"
      "/var/log"
      "/etc/NetworkManager/system-connections"
      "/var/lib/systemd/coredump"
      "/var/lib/nixos"
    ];
    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];
    users.mhelton = {
      directories = [
        {
          directory = ".ssh";
          mode = "0700";
        }
      ];
      files = [
        ".bash_history"
      ];
    };
  };

  # networking
  networking.hostName = "spdr";
  networking.networkmanager.enable = true;
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  system.stateVersion = "23.05";

  time.timeZone = "US/Eastern";

  # tailscale
  sops.secrets.ts_key = {
    sopsFile = ../../secrets/tailscale.yaml;
  };
  services.tailscale-autoconnect = {
    enable = true;
    extraTailscaleArgs = [
      "--advertise-exit-node"
      "--accept-routes"
    ];
    authKeyFile = config.sops.secrets.ts_key.path;
  };

  services.openssh = {
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = "/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    libva-utils
  ];

  sops.secrets.cloudflare = { };
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

  services.plex = {
    enable = true;
    dataDir = "/var/lib/plex";
    openFirewall = true;
    package = pkgs.plexpass;
  };

  services.jellyfin = {
    enable = true;
  };

  services.caddy = {
    enable = true;
    virtualHosts = with caddy-helpers; {
      "jellyfin.${wildcardDomain}" = mkVirtualHost 8096;
      "plex.${wildcardDomain}" = mkVirtualHost 32400;
    };
  };

}
