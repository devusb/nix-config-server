{ lib, pkgs, config, modulesPath, ... }:
{

  deployment = {
    targetHost = "10.42.42.42";
    targetPort = 22;
    targetUser = "nixos";
    buildOnTarget = true;
  };

  systemd.network.links."10-wan" = {
    matchConfig.PermanentMACAddress = "e4:5f:01:d3:28:e9";
    linkConfig.Name = "wan0";
  };

  services.openssh.openFirewall = false;

  networking = {
    hostName = "sophia";
    dhcpcd = {
      enable = true;
      allowInterfaces = [ "wan0" ];
    };
    usePredictableInterfaceNames = true;

    firewall = {
      enable = true;
      trustedInterfaces = [ "lan" "server" ];
      interfaces = {
        wan0.allowedTCPPorts = [ 22 ];
      };
    };

    nat = {
      enable = true;
      externalInterface = "wan0";
      internalInterfaces = [ "lan" "server" ];
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
    };

    interfaces = {
      lan = {
          ipv4.addresses = [
              { address = "10.42.42.42"; prefixLength = 24; }
          ];
          useDHCP = false;
      };
      server = {
          ipv4.addresses = [
              { address = "10.43.43.43"; prefixLength = 24; }
          ];
          useDHCP = false;
      };
    };
  };

  services.dhcpd4 = {
      enable = true;
      extraConfig = ''
      option domain-name-servers 1.1.1.1;
      subnet 10.42.42.0 netmask 255.255.255.0 {
          range 10.42.42.100 10.42.42.199;
          option subnet-mask 255.255.255.0;
          option routers 10.42.42.42;
          interface lan;
      }
      subnet 10.43.43.0 netmask 255.255.255.0 {
          range 10.43.43.100 10.43.43.199;
          option subnet-mask 255.255.255.0;
          option routers 10.43.43.43;
          interface server;
      }
      '';
      interfaces = [ "lan" "server" ];
  };

}
