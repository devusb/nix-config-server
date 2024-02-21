{ lib, config, ... }:
let
  frigateVhost = "frigate.chopper.devusb.us";
in
{
  services.frigate = {
    enable = true;
    hostname = frigateVhost;
    settings = {
      ffmpeg = {
        hwaccel_args = "preset-vaapi";
      };
      cameras = {
        foyer = {
          enabled = true;
          ffmpeg.inputs = [
            {
              path = "rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.40.2:554/cam/realmonitor?channel=1&subtype=0";
              roles = [
                "detect"
              ];
            }
          ];
          detect = {
            width = 1280;
            height = 720;
            enabled = false;
          };
        };
        dining_room = {
          enabled = true;
          ffmpeg.inputs = [
            {
              path = "rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.40.3:554/cam/realmonitor?channel=1&subtype=0";
              roles = [
                "detect"
              ];
            }
          ];
          detect = {
            width = 1280;
            height = 720;
            enabled = false;
          };
        };
      };
    };
  };

  systemd.services.frigate = {
    serviceConfig.EnvironmentFile = config.sops.secrets.frigate.path;
    environment.LIBVA_DRIVER_NAME = "radeonsi";
  };

  services.nginx.virtualHosts."${frigateVhost}" = {
    listen = lib.singleton {
      addr = "unix:/run/nginx/frigate.sock";
    };
  };
  systemd.services.nginx.serviceConfig.RuntimeDirectoryMode = lib.mkForce "0755";

}
