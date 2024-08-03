{ ... }: {
  virtualisation.libvirtd = {
    enable = true;
    allowedBridges = [
      "br0"
    ];
  };

  users.users.mhelton.extraGroups = [ "libvirtd" ];

  systemd.network.networks."20-lan" = {
    matchConfig.Name = ["enp5s0" "vm-*"];
    networkConfig = {
      Bridge = "br0";
    };
  };

  systemd.network.netdevs."br0" = {
    netdevConfig = {
      Name = "br0";
      Kind = "bridge";
    };
  };

  systemd.network.networks."20-lan-bridge" = {
    matchConfig.Name = "br0";
    networkConfig = {
      DHCP = "yes";
    };
    dhcpV4Config.RouteMetric = 2000;
    linkConfig.RequiredForOnline = "routable";
  };

}
