{ inputs, outputs, lib, config, pkgs, ... }: {
  nix = {
    package = pkgs.nixUnstable;
    settings = {
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      auto-optimise-store = true;
      warn-dirty = false;
      trusted-users = [ "mhelton" ];
      substituters = [
        "https://cache.nixos.org/"
        "https://nix-community.cachix.org"
        "https://devenv.cachix.org"
        "https://colmena.cachix.org"
        "https://attic.springhare-egret.ts.net/r2d2"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
        "r2d2:dGjwZKsBup19Wq8b3/W2smJjrw55tC0DnCQhu/qsfb4="
      ];
    };

    gc = {
      automatic = true;
      dates = "monthly";
    };

  };

  environment.systemPackages = with pkgs; [
    neovim
    wget
    git
    nfs-utils
    psmisc
  ];

  # enable passwordless sudo
  security.sudo.wheelNeedsPassword = false;

}
