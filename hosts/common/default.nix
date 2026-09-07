{
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [ ./mhelton.nix ];

  sops = {
    defaultSopsFile = ../../secrets/default.yaml;
    secrets.attic_pull = {
      mode = "0444";
    };
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      warn-dirty = false;
      trusted-users = [ "mhelton" ];
      substituters = lib.mkForce [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://attic.springhare-egret.ts.net/r2d2"
        "https://cache.flox.dev"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "r2d2:dGjwZKsBup19Wq8b3/W2smJjrw55tC0DnCQhu/qsfb4="
        "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
      ];
      netrc-file = config.sops.secrets.attic_pull.path;
    };

    gc = {
      automatic = true;
      dates = lib.mkDefault "weekly";
      options = "--delete-older-than 14d";
    };
  };

  users.users.mhelton.extraGroups = [
    "networkmanager"
    "media"
    "incus-admin"
  ];

  environment.systemPackages = with pkgs; [
    neovim
    wget
    git
    nfs-utils
    psmisc
    curl
    htop
    bottom
    speedtest-go
    tmux
  ];

  # enable passwordless sudo
  security.sudo = {
    enable = lib.mkDefault true;
    wheelNeedsPassword = lib.mkForce false;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkForce "no";
      PasswordAuthentication = false;
    };
  };

  # monitoring
  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = [
        "systemd"
        "ethtool"
        "netstat"
      ];
      disabledCollectors = [ "arp" ];
    };
  };

}
