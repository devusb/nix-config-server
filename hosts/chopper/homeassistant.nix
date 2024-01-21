{ pkgs, lib, ... }: {
  systemd.tmpfiles.settings."homeassistant"."/var/lib/homeassistant".d = {
    mode = "0666";
  };
  virtualisation.oci-containers = {
    backend = "podman";
    containers.homeassistant = {
      volumes = [ "/var/lib/homeassistant:/config" ];
      environment.TZ = "US/Central";
      image = "ghcr.io/home-assistant/home-assistant:2024.1.3";
      extraOptions = [
        "--network=host"
      ];
    };
  };

  services.node-red = {
    enable = true;
  };

}
