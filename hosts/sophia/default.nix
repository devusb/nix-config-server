{ lib, pkgs, modulesPath, ... }:
with lib;
{

  # base image
  imports = [
    ../common
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];
  sdImage.compressImage = false;

  users.mutableUsers = false;

  system.stateVersion = "22.05";
  time.timeZone = "America/Chicago";

  environment.systemPackages = with pkgs; [
    ethtool
    tcpdump
    conntrack-tools
    wol
  ];

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
      clients = singleton { url = "https://loki.chopper.devusb.us/loki/api/v1/push"; };
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

  services.avahi = {
    enable = true;
    reflector = true;
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
              { "hw-address" = "3c:84:6a:b4:93:4f"; "ip-address" = "192.168.10.174"; hostname = "Peloton-Fan"; }
              { "hw-address" = "b0:be:76:ca:de:06"; "ip-address" = "192.168.10.130"; hostname = "Tree"; }
              { "hw-address" = "14:91:82:08:91:21"; "ip-address" = "192.168.10.106"; hostname = "Wemo"; }
              { "hw-address" = "a4:cf:12:de:9c:d6"; "ip-address" = "192.168.10.153"; hostname = "ESP_DE9CD6"; }
              { "hw-address" = "d8:bb:c1:d2:dd:cd"; "ip-address" = "192.168.10.110"; hostname = "tomservo"; }
            ];
          }
          {
            subnet = "192.168.20.0/23";
            pools = [{ pool = "192.168.20.100 - 192.168.21.254"; }];
            "option-data" = [
              { name = "domain-name-servers"; data = "192.168.20.1"; }
              { name = "routers"; data = "192.168.20.1"; }
              { name = "vendor-encapsulated-options"; data = "01:04:c0:a8:14:6d"; csv-format = false; }
            ];
            "reservations" = [
              { "hw-address" = "dc:a6:32:43:d4:5e"; "ip-address" = "192.168.20.138"; hostname = "gaia0"; }
              { "hw-address" = "e4:5f:01:9c:c9:8c"; "ip-address" = "192.168.20.139"; hostname = "gaia1"; }
              { "hw-address" = "9c:6b:00:22:1d:20"; "ip-address" = "192.168.20.109"; hostname = "chopper"; }
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
              { name = "vendor-encapsulated-options"; data = "01:04:c0:a8:14:6d"; csv-format = false; }
            ];
            "reservations" = [ ];
          }
        ];
      };
    };
  };

  services.wolweb = {
    enable = true;
    settings = {
      host = "0.0.0.0";
      port = 8089;
      vdir = "/wolweb";
      bcastip = "255.255.255.255:9";
    };
    devices = [
      {
        name = "tomservo_on";
        mac = "D8:BB:C1:D2:DD:CD";
        ip = "192.168.11.255:40000";
      }
      {
        name = "tomservo_off";
        mac = "CD:DD:D2:C1:BB:D8";
        ip = "192.168.11.255:9";
      }
    ];
  };

}
