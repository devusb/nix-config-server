{ lib, pkgs, config, modulesPath, ... }:
{

  deployment = {
    targetHost = "192.168.10.245";
    targetPort = 22;
    targetUser = "mhelton";
    # buildOnTarget = true;
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
      allowInterfaces = [ "wan0" "eth0" "eth1" ];
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
          option vendor-encapsulated-options 01:04:c0:a8:14:69;
          interface server;
      }
      '';
      interfaces = [ "lan" "server" ];
  };

  # tailscale
  sops.secrets.ts_key = {
    sopsFile = ../tailscale/secrets.yaml;
  };
  services.tailscale.enable = true;
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    # have the job run this shell script
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale
      ${tailscale}/bin/tailscale up --auth-key file:${config.sops.secrets.ts_key.path} --ssh --advertise-exit-node
    '';
  };

}
