{ lib, pkgs, config, modulesPath, inputs, ... }:
{
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
  ];

  deployment = {
    targetHost = "192.168.20.139";
    targetPort = 22;
    targetUser = "mhelton";
  };

  boot = {
    loader.raspberryPi.firmwareConfig = ''
      dtparam=audio=on
    '';
    extraModprobeConfig = ''
      options snd_bcm2835 enable_headphones=1
    '';
  };

  hardware.raspberry-pi."4" = {
    dwc2.enable = true;
    fkms-3d.enable = true;
  };

  networking.hostName = "gaia1";

  sound.enable = true;

  environment.systemPackages = with pkgs; [
    libraspberrypi
  ];

  # tailscale
  sops.secrets.ts_key = {
    sopsFile = ../../secrets/tailscale.yaml;
  };
  services.tailscale = {
    enable = true;
    extraUpFlags = [ "--ssh" ];
    authKeyFile = config.sops.secrets.ts_key.path;
  };

  # monitoring
  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = [ "systemd" "ethtool" "netstat" ];
    };
  };

  services.shairport-sync = {
    enable = true;
    arguments = "-v -o alsa -a Office";
  };
  services.nqptp.enable = true;

}
