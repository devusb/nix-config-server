{ lib, pkgs, config, modulesPath, ... }: {

  system.stateVersion = "22.05";

  deployment = {
    targetHost = "192.168.20.120";
    targetPort = 22;
    targetUser = "root";
  };

  services.blocky = {
    enable = true;
    settings = pkgs.blockyConfig;
  };
}
