{ config, pkgs, lib, ... }: {
  imports = [
    ./voice-assist.nix
  ];

  systemd.tmpfiles.settings."homeassistant"."/var/lib/homeassistant".d = {
    mode = "0666";
  };
  systemd.tmpfiles.settings."node-red"."/var/lib/node-red".d = {
    mode = "0666";
  };
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      homeassistant = {
        volumes = [ "/var/lib/homeassistant:/config" ];
        environment.TZ = "US/Central";
        image = "ghcr.io/home-assistant/home-assistant:2024.2.0";
        extraOptions = [
          "--network=host"
        ];
      };
      node-red = {
        volumes = [ "/var/lib/node-red:/data:U" ];
        environment.TZ = "US/Central";
        image = "nodered/node-red";
        extraOptions = [
          "--network=host"
        ];
        user = config.users.users.root.name;
      };
    };
  };

  services.deploy-backup.backups.homeassistant = {
    files = [
      ''$(find /var/lib/homeassistant/backups -type f -name "*.tar" -exec ls -t {} + | head -n 1)''
      "/var/lib/node-red"
    ];
  };

  services.mosquitto = {
    enable = true;
    listeners = lib.singleton {
      users.homeassistant = {
        hashedPasswordFile = config.sops.secrets.mosquitto.path;
        acl = [
          "readwrite homeassistant/#"
          "readwrite zigbee2mqtt/#"
        ];
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      # mosquitto
      1883

      # HomeKit
      21064
      21066

      # Home Assistant
      8123
    ];
    allowedUDPPorts = [
      # mDNS
      5353
    ];
  };

}
