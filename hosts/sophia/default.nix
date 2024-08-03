{ config, lib, pkgs, modulesPath, ... }:
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

  networking.useNetworkd = true;
  services.resolved.enable = false;

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
  systemd.network.networks."10-wan" = {
    matchConfig.PermanentMACAddress = "e4:5f:01:d3:28:e9";
    networkConfig = {
      DHCP = "yes";
    };
    dhcpV4Config = {
      RouteMetric = 1;
    };
    dhcpV6Config = {
      RouteMetric = 1;
    };
  };
  systemd.network.links."10-wan" = {
    matchConfig.PermanentMACAddress = "e4:5f:01:d3:28:e9";
    linkConfig.Name = "wan0";
  };

  systemd.network.networks."11-fallback" = {
    matchConfig.Name = "wan1";
    networkConfig = {
      DHCP = "yes";
    };
    dhcpV4Config = {
      RouteMetric = 2;
    };
    dhcpV6Config = {
      RouteMetric = 2;
    };
  };

  # backup WAN failover
  sops.secrets.pushover = { };
  systemd.services.wan-check = {
    description = "Checking that primary internet is up";
    serviceConfig = {
      Type = "oneshot";
      EnvironmentFile = config.sops.secrets.pushover.path;
    };
    script = ''
      wan0_status=$(${lib.getExe' pkgs.systemd "networkctl"} status wan0 --json=short | ${lib.getExe pkgs.jq} -r .OperationalState)
      if [[ "''${wan0_status}" == "routable" ]]; then
        if ! ${lib.getExe pkgs.unixtools.ping} -c 1 -w 5 1.1.1.1 > /dev/null 2>&1; then
          echo "Shutting down wan0"
          ${lib.getExe' pkgs.systemd "networkctl"} down wan0
          sleep 5
          ${lib.getExe pkgs.curl} -s --form-string "token=$PINGSHUTDOWN_NOTIFICATIONTOKEN" \
          --form-string "user=$PINGSHUTDOWN_NOTIFICATIONUSER" --form-string "message=sophia: wan0 has been shut down" \
          http://api.pushover.net/1/messages.json > /dev/null 2>&1
        fi
      fi
    '';
  };
  systemd.timers.wan-check = {
    description = "Checking that primary internet is up";
    timerConfig = {
      OnBootSec = "30sec";
      OnUnitActiveSec = "30sec";
    };
    wantedBy = [ "timers.target" ];
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

    usePredictableInterfaceNames = lib.mkDefault true;

    firewall = {
      enable = true;
      allowPing = false;
      logRefusedConnections = false;
      trustedInterfaces = [ "lan" "server" "mgmt" "tailscale0" ];
      interfaces = {
        wan0.allowedTCPPorts = [ ];
        wan1.allowedTCPPorts = [ ];
        guest.allowedTCPPorts = [ 53 ];
        guest.allowedUDPPorts = [ 53 ];
      };
      extraCommands = ''
        iptables -I FORWARD 1 -i guest -d 192.168.0.0/16 -j DROP
        iptables -I FORWARD 1 -i isolated -o wan0 -j DROP
        iptables -I FORWARD 1 -i isolated -o wan1 -j DROP
        iptables -t nat -A POSTROUTING -o wan1 -j MASQUERADE -m mark --mark 0x1
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
      wan1 = {
        id = 1000;
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

  services.kea =
    let
      socket4Config = {
        "socket-type" = "unix";
        "socket-name" = "/run/kea/kea4-ctrl-socket";
      };
    in
    {
      ctrl-agent = {
        enable = true;
        settings = {
          "http-host" = "127.0.0.1";
          "http-port" = 9090;
          "control-sockets".dhcp4 = socket4Config;
        };
      };
      dhcp4 = {
        enable = true;
        settings = {
          "control-socket" = socket4Config;
          "hooks-libraries" = [
            { library = "${pkgs.kea}/lib/kea/hooks/libdhcp_lease_cmds.so"; }
          ];
          "interfaces-config" = {
            interfaces = [ "lan" "server" "guest" "isolated" "mgmt" ];
          };
          "valid-lifetime" = 4000;
          "subnet4" = [
            {
              id = 1;
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
                { "hw-address" = "38:b8:00:7e:a3:c5"; "ip-address" = "192.168.10.160"; hostname = "Living-Room-TV"; }
                { "hw-address" = "00:e4:21:09:56:06"; "ip-address" = "192.168.10.50"; hostname = "PS5-875"; }
                { "hw-address" = "38:42:0b:4e:de:04"; "ip-address" = "192.168.11.13"; hostname = "sonoszp"; }
              ];
            }
            {
              id = 2;
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
              id = 3;
              subnet = "192.168.30.0/24";
              pools = [{ pool = "192.168.30.2 - 192.168.30.254"; }];
              "option-data" = [
                { name = "domain-name-servers"; data = "192.168.30.1"; }
                { name = "routers"; data = "192.168.30.1"; }
              ];
              "reservations" = [ ];
            }
            {
              id = 4;
              subnet = "192.168.40.0/23";
              pools = [{ pool = "192.168.40.200 - 192.168.41.254"; }];
              "option-data" = [
                { name = "domain-name-servers"; data = "192.168.40.1"; }
                { name = "routers"; data = "192.168.40.1"; }
              ];
              "reservations" = [ ];
            }
            {
              id = 5;
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
      {
        name = "durandal_on";
        mac = "70:85:c2:3a:71:05";
        ip = "192.168.11.255:9";
      }
      {
        name = "durandal_off";
        mac = "05:71:3a:c2:85:70";
        ip = "192.168.11.255:9";
      }
    ];
  };

}
