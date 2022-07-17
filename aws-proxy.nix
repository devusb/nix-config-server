{ lib, pkgs, config, modulesPath, ... }:
let pomeriumConfig = pkgs.writeText "pomeriumConfig" (builtins.readFile ./pomerium/config.yaml);
in
{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  system.stateVersion = "22.05";

  deployment = {
    targetHost = "aws-proxy";
    targetPort = 22;
    targetUser = "root";
    replaceUnknownProfiles = true;
  };

  services.pomerium = {
    enable = true;
    configFile = pomeriumConfig;
  };

}
