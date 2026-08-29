{ lib, ... }:
{
  virtualisation.libvirtd = {
    enable = true;
    parallelShutdown = 3;
    onShutdown = "shutdown";
    allowedBridges = [
      "br0"
    ];
  };

  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    defaultNetwork.settings = {
      dns_enabled = true;
    };
  };
  hardware.nvidia-container-toolkit.enable = true;
  # https://github.com/NixOS/nixpkgs/issues/463645
  systemd.services.nvidia-container-toolkit-cdi-generator = {
    unitConfig.DefaultDependencies = false;
    after = lib.mkForce [ ];
  };

  users.users.mhelton.extraGroups = [ "libvirtd" ];

  systemd.network.networks."20-lan" = {
    matchConfig.Name = [
      "enp6s0"
      "vm-*"
    ];
    networkConfig = {
      Bridge = "br0";
    };
  };

  systemd.network.netdevs."br0" = {
    netdevConfig = {
      Name = "br0";
      Kind = "bridge";
      MACAddress = "9c:6b:00:22:1d:20";
    };
  };

  systemd.network.networks."20-lan-bridge" = {
    matchConfig.Name = "br0";
    address = [ "192.168.20.109/23" ];
    gateway = [ "192.168.20.1" ];
    dns = [ "192.168.20.1" ];
    linkConfig.RequiredForOnline = "routable";
  };

}
