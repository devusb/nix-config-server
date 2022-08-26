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
    htop
    ethtool
    tcpdump
    conntrack-tools
  ];

  # DNS
  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = [ "127.0.0.1" ];
        port = "5335";
        access-control = [
          "0.0.0.0/0 refuse"
          "127.0.0.0/8 allow"
        ];
      };
    };
  };
  services.blocky = {
    enable = true;
    settings = pkgs.blockyConfig // { upstream = { default = [ "127.0.0.1:5335" ]; }; };
  };
  systemd.services.blocky.after = [ "unbound.service" ];

  # router configuration
  systemd.network.links."10-wan" = {
    matchConfig.PermanentMACAddress = "e4:5f:01:d3:28:e9";
    linkConfig.Name = "wan0";
  };

  services.openssh.openFirewall = false;

  networking = {
    hostName = "sophia";

    # use static IP-based timeservers since DNS may not be available at boot
    timeServers = [
      "216.239.35.0"
      "216.239.35.4"
      "216.239.35.8"
      "216.239.35.12"
    ];

    dhcpcd = {
      enable = true;
      allowInterfaces = [ "wan0" ];
    };
    usePredictableInterfaceNames = true;

    firewall = {
      enable = true;
      allowPing = false;
      logRefusedConnections = false;
      trustedInterfaces = [ "lan" "server" "mgmt" "tailscale0" ];
      interfaces = {
        wan0.allowedTCPPorts = [ ];
        guest.allowedTCPPorts = [ 53 ];
        guest.allowedUDPPorts = [ 53 ];
      };
      extraCommands = ''
        iptables -I FORWARD 1 -i guest -d 192.168.0.0/16 -j DROP
      '';
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
      subnet 192.168.10.0 netmask 255.255.254.0 {
          option domain-name-servers 192.168.10.1;
          range 192.168.10.50 192.168.11.254;
          option subnet-mask 255.255.254.0;
          option routers 192.168.10.1;
          interface lan;
      }

      subnet 192.168.20.0 netmask 255.255.254.0 {
          option domain-name-servers 192.168.20.1;
          range 192.168.20.100 192.168.21.254;
          option subnet-mask 255.255.254.0;
          option routers 192.168.20.1;
          interface server;
          option vendor-encapsulated-options 01:04:c0:a8:14:69;
      }

      subnet 192.168.30.0 netmask 255.255.255.0 {
          option domain-name-servers 192.168.30.1;
          range 192.168.30.2 192.168.30.254;
          option subnet-mask 255.255.255.0;
          option routers 192.168.30.1;
          interface guest;
      }

      subnet 192.168.99.0 netmask 255.255.255.0 {
          option domain-name-servers 192.168.99.1;
          range 192.168.99.200 192.168.99.254;
          option subnet-mask 255.255.255.0;
          option routers 192.168.99.1;
          interface mgmt;
          option vendor-encapsulated-options 01:04:c0:a8:14:69;
      }

      host docker {
        hardware ethernet 5a:33:e2:da:ec:be;
        fixed-address 192.168.20.133;
      }
      host fileshare {
        hardware ethernet 3a:c9:f7:cb:0a:b3;
        fixed-address 192.168.20.131;
      }
      host gaia0 {
        hardware ethernet dc:a6:32:43:d4:5e;
        fixed-address 192.168.20.138;
      }
      host gaia1 {
        hardware ethernet e4:5f:01:9c:c9:8c;
        fixed-address 192.168.20.139;
      }
      host gaia3 {
        hardware ethernet e6:ca:67:81:71:fc;
        fixed-address 192.168.20.140;
      }
      host nfs-export {
        hardware ethernet e6:38:e7:50:fa:fb;
        fixed-address 192.168.20.137;
      }
      host plex {
        hardware ethernet f6:c3:6b:61:f7:fb;
        fixed-address 192.168.20.130;
      }
      host radarr {
        hardware ethernet 46:23:ef:27:7d:9a;
        fixed-address 192.168.20.135;
      }
      host unifi {
        hardware ethernet 36:0C:72:1C:83:84;
        fixed-address 192.168.20.105;
      }
      host GR_Lamp {
        hardware ethernet b0:be:76:ca:dc:9f;
        fixed-address 192.168.10.131;
      }
      host HDHR-1068A2E8 {
        hardware ethernet 00:18:dd:06:8a:2e;
        fixed-address 192.168.10.137;
      }
      host homeassistant {
        hardware ethernet 7A:10:41:6E:3E:A4;
        fixed-address 192.168.10.119;
      }
      host Peloton-Fan {
        hardware ethernet 3c:84:6a:b4:93:4f;
        fixed-address 192.168.10.174;
      }
      host RMMINI-18-6b-74 {
        hardware ethernet 78:0f:77:18:6b:74;
        fixed-address 192.168.10.120;
      }
      host Tree {
        hardware ethernet b0:be:76:ca:de:06;
        fixed-address 192.168.10.130;
      }
      host Wemo {
        hardware ethernet 14:91:82:08:91:21;
        fixed-address 192.168.10.106;
      }
      host tasmota-260128-0296 {
        hardware ethernet 98:CD:AC:26:01:28;
        fixed-address 192.168.10.140;
      }
      host ESP_DE9CD6 {
        hardware ethernet a4:cf:12:de:9c:d6;
        fixed-address 192.168.10.153;
      }
      host blocky {
        hardware ethernet 9A:A4:BB:CF:29:D5;
        fixed-address 192.168.20.120;
      }
    '';
    interfaces = [ "lan" "server" "guest" "mgmt" ];
  };

}
