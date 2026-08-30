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
      substituters = [
        "https://nix-community.cachix.org"
        "https://devenv.cachix.org"
        "https://colmena.cachix.org"
        "https://devusb.cachix.org"
        "https://attic.springhare-egret.ts.net/r2d2"
        "https://cache.flox.dev"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
        "devusb.cachix.org-1:erGk4mgcE03SfS6LbHz2IAIHAN3sR2Ee5Shb0Qs8C3A="
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
