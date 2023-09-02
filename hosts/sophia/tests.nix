({ pkgs, lib, ... }: {
  name = "sophia";

  nodes = {
    sophia = { config, pkgs, ... }: {
      imports = [
        ./default.nix
      ];
      virtualisation = {
        memorySize = 8192;
        cores = 4;
        interfaces.enp1s0.vlan = 0;
      };
      nixpkgs.hostPlatform = "x86_64-linux";
      systemd.network.links."11-wan-virt" = {
        matchConfig.OriginalName = "eth0";
        linkConfig.Name = "wan0";
      };
      services.promtail.enable = lib.mkForce false;
    };

    lanClient = { config, pkgs, ... }: {
      virtualisation.vlans = [ 0 ];
      networking = {
        useNetworkd = true;
        useDHCP = false;
        firewall.enable = false;
        interfaces.lan.useDHCP = true;
        vlans = {
          lan = {
            id = 10;
            interface = "eth1";
          };
        };
      };
    };

    serverClient = { config, pkgs, ... }: {
      virtualisation.vlans = [ 0 ];
      networking = {
        useNetworkd = true;
        useDHCP = false;
        firewall.enable = false;
        interfaces.server = {
          useDHCP = true;
          macAddress = "B6:E3:2E:6C:E0:76";
        };
        vlans = {
          server = {
            id = 20;
            interface = "eth1";
          };
        };
      };
    };

  };

  testScript = { ... }: ''
    start_all()
    sophia.wait_for_unit("kea-dhcp4-server.service")

    lanClient.wait_for_unit("systemd-networkd-wait-online.service")
    lanClient.succeed("ip add | grep 192.168.10.50")

    serverClient.wait_for_unit("systemd-networkd-wait-online.service")
    serverClient.succeed("ip add | grep 192.168.20.106")

    lanClient.wait_until_succeeds("ping -c 5 192.168.10.1")
    lanClient.wait_until_succeeds("ping -c 5 192.168.20.106")
    serverClient.wait_until_succeeds("ping -c 5 192.168.20.1")
    serverClient.wait_until_succeeds("ping -c 5 192.168.10.50")
  '';

})