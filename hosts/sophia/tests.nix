(
  { lib, ... }:
  {
    name = "sophia";

    nodes = {
      sophia =
        { inputs, ... }:
        {
          imports = [
            ./default.nix
            inputs.nix-packages.nixosModules.default
            inputs.sops-nix.nixosModules.sops
          ];
          virtualisation = {
            memorySize = 8192;
            cores = 4;
            interfaces.enp1s0.vlan = 0;
          };
          systemd.network.links."11-wan-virt" = {
            matchConfig.OriginalName = "eth0";
            linkConfig.Name = "wan0";
          };
          services.promtail.enable = lib.mkForce false;
        };

      lanClient =
        { ... }:
        {
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

      serverClient =
        { ... }:
        {
          virtualisation.vlans = [ 0 ];
          networking = {
            useNetworkd = true;
            useDHCP = false;
            firewall.enable = false;
            interfaces.server = {
              useDHCP = true;
              macAddress = "9c:6b:00:22:1d:20";
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

    testScript =
      { ... }:
      ''
        start_all()
        sophia.wait_for_unit("kea-dhcp4-server.service")

        lanClient.systemctl("start systemd-networkd-wait-online.service")
        lanClient.wait_for_unit("systemd-networkd-wait-online.service")
        lanClient.succeed("ip add | grep 192.168.10.51")

        serverClient.systemctl("start systemd-networkd-wait-online.service")
        serverClient.wait_for_unit("systemd-networkd-wait-online.service")
        serverClient.succeed("ip add | grep 192.168.20.109")

        lanClient.wait_until_succeeds("ping -c 5 192.168.10.1")
        lanClient.wait_until_succeeds("ping -c 5 192.168.20.109")
        serverClient.wait_until_succeeds("ping -c 5 192.168.20.1")
        serverClient.wait_until_succeeds("ping -c 5 192.168.10.51")
      '';

  }
)
