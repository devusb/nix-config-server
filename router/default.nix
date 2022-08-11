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

  system.stateVersion = "22.05";
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
  ];

  # router configuration
  systemd.network.links."10-wan" = {
    matchConfig.PermanentMACAddress = "e4:5f:01:d3:28:e9";
    linkConfig.Name = "wan0";
  };

  services.openssh.openFirewall = false;

  networking = {
    hostName = "sophia";
    dhcpcd = {
      enable = true;
      allowInterfaces = [ "wan0" "eth0" "eth1" ];
    };
    usePredictableInterfaceNames = true;

    firewall = {
      enable = true;
      trustedInterfaces = [ "lan" "server" "mgmt" ];
      interfaces = {
        wan0.allowedTCPPorts = [ 22 ];
      };
    };

    nat = {
      enable = true;
      externalInterface = "wan0";
      internalInterfaces = [ "lan" "server" "guest" "mgmt" ];
    };

    vlans = {
      lan = {
        id = 10;
        interface = "enp1s0";
      };
      server = {
        id = 20;
        interface = "enp1s0";
      };
      guest = {
        id = 30;
        interface = "enp1s0";
      };
      mgmt = {
        id = 99;
        interface = "enp1s0";
      };
    };

    interfaces = {
      lan = {
          ipv4.addresses = [
              { address = "192.168.10.1"; prefixLength = 23; }
          ];
          useDHCP = false;
      };
      server = {
          ipv4.addresses = [
              { address = "192.168.20.1"; prefixLength = 23; }
          ];
          useDHCP = false;
      };
      guest = {
          ipv4.addresses = [
              { address = "192.168.30.1"; prefixLength = 24; }
          ];
          useDHCP = false;
      };
      mgmt = {
          ipv4.addresses = [
              { address = "192.168.99.1"; prefixLength = 24; }
          ];
          useDHCP = false;
      };
    };
  };

  services.dhcpd4 = {
      enable = true;
      extraConfig = ''
      option domain-name-servers 1.1.1.1;
      subnet 192.168.10.0 netmask 255.255.254.0 {
          range 192.168.10.50 192.168.11.254;
          option subnet-mask 255.255.254.0;
          option routers 192.168.10.1;
          interface lan;
      }
      subnet 192.168.20.0 netmask 255.255.254.0 {
          range 192.168.20.100 192.168.21.254;
          option subnet-mask 255.255.254.0;
          option routers 192.168.20.1;
          interface server;
          option vendor-encapsulated-options 01:04:c0:a8:14:69;
      }
      subnet 192.168.30.0 netmask 255.255.255.0 {
          range 192.168.30.2 192.168.30.254;
          option subnet-mask 255.255.255.0;
          option routers 192.168.30.1;
          interface guest;
      }
      subnet 192.168.99.0 netmask 255.255.255.0 {
          range 192.168.99.200 192.168.99.254;
          option subnet-mask 255.255.255.0;
          option routers 192.168.99.1;
          interface mgmt;
          option vendor-encapsulated-options 01:04:c0:a8:14:69;
      }
      '';
      interfaces = [ "lan" "server" "guest" "mgmt" ];
  };

}
