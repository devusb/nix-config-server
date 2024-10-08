{ config, ... }: {
  sops.secrets.iodine_password = {
    sopsFile = ../../secrets/default.yaml;
    owner = "iodined";
  };

  networking.firewall = {
    allowedUDPPorts = [ 53 ];
    trustedInterfaces = [ "dns0" ];
  };

  networking.nat = {
    enable = true;
    externalInterface = "enp0s6";
    internalInterfaces = [ "dns0" ];
  };

  services.iodine.server = {
    enable = true;
    domain = "t1.goon.ventures";
    ip = "10.53.0.1/16";
    passwordFile = config.sops.secrets.iodine_password.path;
    extraConfig = "-c";
  };
  systemd.services.iodined.serviceConfig = {
    RestartSec = "30";
    Restart = "on-failure";
  };

}
