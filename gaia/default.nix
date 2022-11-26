{ lib, pkgs, config, modulesPath, ... }:
with lib;
{

  # base image
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];
  sdImage.compressImage = false;

  users.mutableUsers = false;
  users.users.mhelton = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };
  users.extraUsers.mhelton.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHD+tZ4hf4MhEW+akoZbXPN3Zi4cijSkQlX6bZlnV+Aq mhelton@gmail.com"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5rmy7r//z1fARqDe6sIu5D4Nt5uD3rRvwtADDgb+sS6slv6I51Gm2rKcxDIHgYBSyhTDIuhNHlnn+cyJK4ZPxyZFxF0Vy0fZIFG3Y7AqkyQ0oXEDGYyqfL8U0mi0uGKmVW02T45w16REJG3x77uncw8VVxdEpKuYw+wk7uRlQpP/UiFYWsX4NS9rUS/aZrYZ2ys1/dCPqvz4KPXk7SZrqyqkiumIr8O0wluYI5FwhMtd3xpD9AQVI3V0zjYZPwesL+BkW4CAAm5dSnsns3haAuWHti/QLSR+90k15KhflXlq6JDzE4jrMbd1DYZqoVuTgoZxDB3HDJwEwpbYCWKLFaGR6ZDhE3NeFikNkdDRrlIcrK1wJCEO2QuDZ43IE/bDhLhOmqfliL6kRr+2G1AvY4Hr0jnJHbbHqN9mES5+VJZuhH2ii+QHS70VZN0NNQv7f0QJqiTVcUVuPXksBp6oojbkXK79CWd1X0u3shd6XinZ5N3KAD4PT8zlTCmglXNYamc1JpRqKzgFwgFcljXpHwtfuezpNVmzo1Vqi6Ib9S8qJi9rahhsafYP3Y+8EV3Ii3oXmGQBSwumAHCQIkiQ/Sc+FRS02GRgWuYOaQfvW99kLXbX+0eCMSdCJSLC+H1cO2b451qpDGGDnH9w+EvS04oyv4yufpwFlhys7qfU6HQ== mhelton@gmail.com"
  ];

  security.sudo = {
    enable = mkDefault true;
    wheelNeedsPassword = mkForce false;
  };

  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
  };

  networking.firewall.enable = false;

  system.stateVersion = "22.11";
  time.timeZone = "America/Chicago";

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.auto-optimise-store = true;
    settings.trusted-users = [ "mhelton" ];
  };

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    micro
    wget
    curl
    htop
  ];

}
