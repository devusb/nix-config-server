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
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  system.stateVersion = "22.05";
  time.timeZone = "America/Chicago";

  nix = {
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

  # monitoring
  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = [ "systemd" "ethtool" "netstat" ];
    };
  };

  services.journald.extraConfig = ''
    Storage=volatile
  '';
  services.promtail = with lib; {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9080;
        grpc_listen_port = 0;
      };
      clients = singleton { url = "http://192.168.20.133:3100/loki/api/v1/push"; };
      scrape_configs = singleton {
        job_name = "sophia-journal";
        journal = {
          json = true;
          max_age = "12h";
          path = "/run/log/journal";
          labels = {
            job = "sophia-journal";
          };
        };
        relabel_configs = singleton {
          source_labels = singleton "__journal__systemd_unit";
          target_label = "unit";
        };
      };
    };
  };

  # DNS
  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = [ "127.0.0.1" ];
        port = "5353";
        access-control = [
          "0.0.0.0/0 refuse"
          "127.0.0.0/8 allow"
        ];
      };
    };
  };
  services.blocky = {
    enable = true;
    settings = import ../../images/blocky-fly/blocky-config.nix { };
  };
  systemd.services.blocky.after = [ "network-online.target" "unbound.service" ];
  systemd.services.blocky.wants = [ "network-online.target" "unbound.service" ];
  systemd.services.blocky-check = {
    description = "checking that ad-blocking is working";
    serviceConfig.Type = "oneshot";
    script = ''
      if [[ $(${pkgs.dig}/bin/dig doubleclick.net +short) != "0.0.0.0" ]]; then systemctl restart blocky; fi
    '';
  };
  systemd.timers.blocky-check = {
    description = "checking that ad-blocking is working";
    timerConfig = {
      OnBootSec = "10min";
    };
    wantedBy = [ "timers.target" ];
  };


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
    usePredictableInterfaceNames = lib.mkDefault true;

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
        iptables -I FORWARD 1 -i isolated -o wan0 -j DROP
      '';
    };

    nat = {
      enable = true;
      externalInterface = "wan0";
      internalInterfaces = [ "lan" "server" "guest" "isolated" "mgmt" ];
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
      isolated = {
        id = 40;
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
      isolated = {
        ipv4.addresses = [
          { address = "192.168.40.1"; prefixLength = 23; }
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

  services.kea = {
    dhcp4 = {
      enable = true;
      settings = {
        "interfaces-config" = {
          interfaces = [ "lan" "server" "guest" "isolated" "mgmt" ];
        };
        "valid-lifetime" = 4000;
        "subnet4" = [
          {
            subnet = "192.168.10.0/23";
            pools = [{ pool = "192.168.10.50 - 192.168.11.254"; }];
            "option-data" = [
              { name = "domain-name-servers"; data = "192.168.10.1"; }
              { name = "routers"; data = "192.168.10.1"; }
            ];
            "reservations" = [
              { "hw-address" = "b0:be:76:ca:dc:9f"; "ip-address" = "192.168.10.131"; hostname = "GR_Lamp"; }
              { "hw-address" = "00:18:dd:06:8a:2e"; "ip-address" = "192.168.10.137"; hostname = "HDHR-1068A2E8"; }
              { "hw-address" = "7A:10:41:6E:3E:A4"; "ip-address" = "192.168.10.119"; hostname = "homeassistant"; }
              { "hw-address" = "3c:84:6a:b4:93:4f"; "ip-address" = "192.168.10.174"; hostname = "Peloton-Fan"; }
              { "hw-address" = "78:0f:77:18:6b:74"; "ip-address" = "192.168.10.120"; hostname = "RMMINI-18-6b-74"; }
              { "hw-address" = "b0:be:76:ca:de:06"; "ip-address" = "192.168.10.130"; hostname = "Tree"; }
              { "hw-address" = "14:91:82:08:91:21"; "ip-address" = "192.168.10.106"; hostname = "Wemo"; }
              { "hw-address" = "98:CD:AC:26:01:28"; "ip-address" = "192.168.10.140"; hostname = "tasmota-260128-0296"; }
              { "hw-address" = "a4:cf:12:de:9c:d6"; "ip-address" = "192.168.10.153"; hostname = "ESP_DE9CD6"; }
            ];
          }
          {
            subnet = "192.168.20.0/23";
            pools = [{ pool = "192.168.20.100 - 192.168.21.254"; }];
            "option-data" = [
              { name = "domain-name-servers"; data = "192.168.20.1"; }
              { name = "routers"; data = "192.168.20.1"; }
              { name = "vendor-encapsulated-options"; data = "01:04:c0:a8:14:69"; csv-format = false; }
            ];
            "reservations" = [
              { "hw-address" = "5a:33:e2:da:ec:be"; "ip-address" = "192.168.20.133"; hostname = "docker"; }
              { "hw-address" = "3a:c9:f7:cb:0a:b3"; "ip-address" = "192.168.20.131"; hostname = "fileshare"; }
              { "hw-address" = "dc:a6:32:43:d4:5e"; "ip-address" = "192.168.20.138"; hostname = "gaia0"; }
              { "hw-address" = "e4:5f:01:9c:c9:8c"; "ip-address" = "192.168.20.139"; hostname = "gaia1"; }
              { "hw-address" = "e6:38:e7:50:fa:fb"; "ip-address" = "192.168.20.137"; hostname = "nfs-export"; }
              { "hw-address" = "f6:c3:6b:61:f7:fb"; "ip-address" = "192.168.20.130"; hostname = "plex"; }
              { "hw-address" = "46:23:ef:27:7d:9a"; "ip-address" = "192.168.20.135"; hostname = "radarr"; }
              { "hw-address" = "36:0C:72:1C:83:84"; "ip-address" = "192.168.20.105"; hostname = "unifi"; }
              { "hw-address" = "9A:A4:BB:CF:29:D5"; "ip-address" = "192.168.20.120"; hostname = "blocky"; }
              { "hw-address" = "22:71:BA:E3:0B:6C"; "ip-address" = "192.168.20.101"; hostname = "arr"; }
              { "hw-address" = "36:77:FD:22:7E:9C"; "ip-address" = "192.168.20.102"; hostname = "atuin"; }
              { "hw-address" = "42:B5:CC:D5:0F:37"; "ip-address" = "192.168.20.103"; hostname = "vault"; }
              { "hw-address" = "B6:E3:2E:6C:E0:76"; "ip-address" = "192.168.20.106"; hostname = "attic"; }
            ];
          }
          {
            subnet = "192.168.30.0/24";
            pools = [{ pool = "192.168.30.2 - 192.168.30.254"; }];
            "option-data" = [
              { name = "domain-name-servers"; data = "192.168.30.1"; }
              { name = "routers"; data = "192.168.30.1"; }
            ];
            "reservations" = [ ];
          }
          {
            subnet = "192.168.40.0/23";
            pools = [{ pool = "192.168.40.200 - 192.168.41.254"; }];
            "option-data" = [
              { name = "domain-name-servers"; data = "192.168.40.1"; }
              { name = "routers"; data = "192.168.40.1"; }
            ];
            "reservations" = [ ];
          }
          {
            subnet = "192.168.99.0/24";
            pools = [{ pool = "192.168.99.200 - 192.168.99.254"; }];
            "option-data" = [
              { name = "domain-name-servers"; data = "192.168.99.1"; }
              { name = "routers"; data = "192.168.99.1"; }
              { name = "vendor-encapsulated-options"; data = "01:04:c0:a8:14:69"; csv-format = false; }
            ];
            "reservations" = [ ];
          }
        ];
      };
    };
  };

}
