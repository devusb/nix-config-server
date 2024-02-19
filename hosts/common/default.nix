{ inputs, outputs, lib, config, pkgs, ... }: {
  nix = {
    package = pkgs.nixUnstable;
    settings = {
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      auto-optimise-store = true;
      warn-dirty = false;
      trusted-users = [ "mhelton" ];
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
