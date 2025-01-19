{ pkgs, lib, ... }:
{
  microvm = {
    mem = 8192;
    vcpu = 4;
    interfaces = [
      {
        type = "tap";
        id = "vm-kube0";
        mac = "02:00:00:00:00:01";
      }
    ];
    shares = [
      {
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
      }
    ];
    volumes = [
      {
        image = "etc.img";
        label = "etc";
        mountPoint = "/etc";
        size = 500;
        autoCreate = true;
      }
      {
        image = "var.img";
        label = "var";
        mountPoint = "/var";
        size = 8192;
        autoCreate = true;
      }
    ];
  };

  # enable passwordless sudo
  security.sudo = {
    enable = lib.mkDefault true;
    wheelNeedsPassword = lib.mkForce false;
  };

  users.users.mhelton = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };
  users.users.mhelton.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHD+tZ4hf4MhEW+akoZbXPN3Zi4cijSkQlX6bZlnV+Aq mhelton@gmail.com"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5rmy7r//z1fARqDe6sIu5D4Nt5uD3rRvwtADDgb+sS6slv6I51Gm2rKcxDIHgYBSyhTDIuhNHlnn+cyJK4ZPxyZFxF0Vy0fZIFG3Y7AqkyQ0oXEDGYyqfL8U0mi0uGKmVW02T45w16REJG3x77uncw8VVxdEpKuYw+wk7uRlQpP/UiFYWsX4NS9rUS/aZrYZ2ys1/dCPqvz4KPXk7SZrqyqkiumIr8O0wluYI5FwhMtd3xpD9AQVI3V0zjYZPwesL+BkW4CAAm5dSnsns3haAuWHti/QLSR+90k15KhflXlq6JDzE4jrMbd1DYZqoVuTgoZxDB3HDJwEwpbYCWKLFaGR6ZDhE3NeFikNkdDRrlIcrK1wJCEO2QuDZ43IE/bDhLhOmqfliL6kRr+2G1AvY4Hr0jnJHbbHqN9mES5+VJZuhH2ii+QHS70VZN0NNQv7f0QJqiTVcUVuPXksBp6oojbkXK79CWd1X0u3shd6XinZ5N3KAD4PT8zlTCmglXNYamc1JpRqKzgFwgFcljXpHwtfuezpNVmzo1Vqi6Ib9S8qJi9rahhsafYP3Y+8EV3Ii3oXmGQBSwumAHCQIkiQ/Sc+FRS02GRgWuYOaQfvW99kLXbX+0eCMSdCJSLC+H1cO2b451qpDGGDnH9w+EvS04oyv4yufpwFlhys7qfU6HQ== mhelton@gmail.com"
  ];

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkForce "no";
      PasswordAuthentication = false;
    };
  };

  networking.firewall.enable = false;

  networking.hostName = "kube0";
  environment.systemPackages = with pkgs; [
    neovim
    bottom
  ];
  systemd.network.enable = true;
  systemd.network.networks."20-lan" = {
    matchConfig.Type = "ether";
    networkConfig = {
      Address = "192.168.20.70/23";
      Gateway = "192.168.20.1";
      DNS = "8.8.8.8";
    };
  };

  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = [
      "--flannel-backend wireguard-native"
    ];
  };

}
