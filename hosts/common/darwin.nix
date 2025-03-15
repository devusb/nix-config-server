{
  config,
  pkgs,
  ...
}:
{
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
      warn-dirty = false;
      trusted-users = [ "mhelton" ];
      substituters = [
        "https://nix-community.cachix.org"
        "https://devenv.cachix.org"
        "https://colmena.cachix.org"
        "https://devusb.cachix.org"
        "https://attic.springhare-egret.ts.net/r2d2"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
        "devusb.cachix.org-1:erGk4mgcE03SfS6LbHz2IAIHAN3sR2Ee5Shb0Qs8C3A="
        "r2d2:dGjwZKsBup19Wq8b3/W2smJjrw55tC0DnCQhu/qsfb4="
      ];
      netrc-file = config.sops.secrets.attic_pull.path;
    };

    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
    };
    optimise.automatic = true;
  };

  users.knownUsers = [ "nix" ];

  users.users.mhelton.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHD+tZ4hf4MhEW+akoZbXPN3Zi4cijSkQlX6bZlnV+Aq mhelton@gmail.com"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5rmy7r//z1fARqDe6sIu5D4Nt5uD3rRvwtADDgb+sS6slv6I51Gm2rKcxDIHgYBSyhTDIuhNHlnn+cyJK4ZPxyZFxF0Vy0fZIFG3Y7AqkyQ0oXEDGYyqfL8U0mi0uGKmVW02T45w16REJG3x77uncw8VVxdEpKuYw+wk7uRlQpP/UiFYWsX4NS9rUS/aZrYZ2ys1/dCPqvz4KPXk7SZrqyqkiumIr8O0wluYI5FwhMtd3xpD9AQVI3V0zjYZPwesL+BkW4CAAm5dSnsns3haAuWHti/QLSR+90k15KhflXlq6JDzE4jrMbd1DYZqoVuTgoZxDB3HDJwEwpbYCWKLFaGR6ZDhE3NeFikNkdDRrlIcrK1wJCEO2QuDZ43IE/bDhLhOmqfliL6kRr+2G1AvY4Hr0jnJHbbHqN9mES5+VJZuhH2ii+QHS70VZN0NNQv7f0QJqiTVcUVuPXksBp6oojbkXK79CWd1X0u3shd6XinZ5N3KAD4PT8zlTCmglXNYamc1JpRqKzgFwgFcljXpHwtfuezpNVmzo1Vqi6Ib9S8qJi9rahhsafYP3Y+8EV3Ii3oXmGQBSwumAHCQIkiQ/Sc+FRS02GRgWuYOaQfvW99kLXbX+0eCMSdCJSLC+H1cO2b451qpDGGDnH9w+EvS04oyv4yufpwFlhys7qfU6HQ== mhelton@gmail.com"
  ];

  environment.systemPackages = with pkgs; [
    neovim
    wget
    git
    curl
    htop
    bottom
    speedtest-go
    tmux
    kitty
  ];

  # monitoring
  services.prometheus.exporters = {
    node = {
      enable = true;
    };
  };

  services.tailscale = {
    enable = true;
  };

}
