{ lib, pkgs, config, modulesPath, ... }:
{

  system.stateVersion = "22.05";

  deployment = {
    targetHost = "192.168.20.102";
    targetPort = 22;
    targetUser = "root";
  };

  networking.hostName = "atuin";

  services.atuin = {
    enable = true;
    host = "0.0.0.0";
  };

  services.caddy = {
    enable = true;
    extraConfig = ''
      ${config.networking.hostName}.springhare-egret.ts.net
      reverse_proxy :8888
    '';
  };

}
