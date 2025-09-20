{ config, ... }:
{
  deployment = {
    targetHost = "192.168.20.138";
    targetPort = 22;
    targetUser = "mhelton";
  };

  networking.hostName = "gaia0";

  # tailscale
  sops.secrets.ts_key = {
    sopsFile = ../../secrets/tailscale.yaml;
  };
  services.tailscale = {
    enable = true;
    extraUpFlags = [ "--ssh" ];
    authKeyFile = config.sops.secrets.ts_key.path;
  };

  virtualisation.oci-containers.containers = {
    zwave-js-ui = {
      image = "zwavejs/zwave-js-ui:9.28.0";
      ports = [
        "8091:8091"
        "3000:3000"
      ];
      volumes = [ "/var/lib/zwave-js-ui/store:/usr/src/app/store" ];
      extraOptions = [
        "--device=/dev/serial/by-id/usb-Silicon_Labs_HubZ_Smart_Home_Controller_61200B7D-if00-port0:/dev/zwave"
      ];
    };
  };

  sops.secrets."zigbee2mqtt.yaml" = {
    sopsFile = ../../secrets/default.yaml;
    owner = "zigbee2mqtt";
  };
  services.zigbee2mqtt = {
    enable = true;
    settings = {
      homeassistant.enable = true;
      frontend = true;
      serial = {
        port = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_281736b2e112ec118bd021c7bd930c07-if00-port0";
      };
      mqtt = {
        server = "mqtt://chopper:1883";
        user = "!${config.sops.secrets."zigbee2mqtt.yaml".path} user";
        password = "!${config.sops.secrets."zigbee2mqtt.yaml".path} password";
      };
    };
  };
  systemd.services.zigbee2mqtt = {
    serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
  };

  services.deploy-backup = {
    enable = true;
    backups.zigwave = {
      files = [
        "/var/lib/zigbee2mqtt"
        "/var/lib/zwave-js-ui"
      ];
    };
  };

}
