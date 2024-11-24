{ pkgs, config, ... }:
let
  shairportConfig = ''
    general = {
      audio_backend_latency_offset_in_seconds = -0.1
    }
  '';
in
{
  deployment = {
    targetHost = "192.168.20.139";
    targetPort = 22;
    targetUser = "mhelton";
  };

  boot = {
    extraModprobeConfig = ''
      options snd_bcm2835 enable_headphones=1
    '';
  };

  hardware.raspberry-pi."4" = {
    dwc2.enable = true;
    fkms-3d.enable = true;
    audio.enable = true;
  };

  networking.hostName = "gaia1";

  # tailscale
  sops.secrets.ts_key = {
    sopsFile = ../../secrets/tailscale.yaml;
  };
  services.tailscale = {
    enable = true;
    extraUpFlags = [ "--ssh" ];
    authKeyFile = config.sops.secrets.ts_key.path;
  };

  services.shairport-sync = {
    enable = true;
    arguments = "-v -o alsa -a Office -c ${pkgs.writeText "shairport-sync.conf" shairportConfig}";
  };
  services.nqptp.enable = true;

}
