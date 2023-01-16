{ lib, pkgs, config, modulesPath, ... }:
{

  deployment = {
    targetHost = "192.168.20.138";
    targetPort = 22;
    targetUser = "mhelton";
  };

  networking.hostName = "gaia0";

  services.tailscale-autoconnect.enable = true;

  virtualisation.oci-containers.containers = {
    zwave-js-ui = {
      image = "zwavejs/zwave-js-ui:8.6.3";
      ports = [ "8091:8091" "3000:3000" ];
      volumes = [ "/var/lib/zwave-js-ui/store:/usr/src/app/store" ];
      extraOptions = [ "--device=/dev/serial/by-id/usb-Silicon_Labs_HubZ_Smart_Home_Controller_61200B7D-if00-port0:/dev/zwave" ];
    };
  };

}
