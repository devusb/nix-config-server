{ pkgs, ... }:
{
  imports = [
    ../common/darwin.nix
    ../common/builder.nix
  ];

  system.stateVersion = 5;

  environment.systemPackages = with pkgs; [
    utm
  ];

  networking.hostName = "cortana";

  services.message-bridge.enable = true;

}
