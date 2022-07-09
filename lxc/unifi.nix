{ lib, pkgs, config, modulesPath, ... }: {
  imports = [
    ../template
  ];

  system.stateVersion = "22.05";

  deployment = {
    targetHost = "192.168.20.105";
    targetPort = 22;
    targetUser = "root";
    replaceUnknownProfiles = true;
  };

  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unifi6;
  };
}
