{ lib, pkgs, config, modulesPath, ... }:
{

  deployment = {
    targetHost = "192.168.10.1";
    targetPort = 22;
    targetUser = "mhelton";
  };

}
