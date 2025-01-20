{ ... }:
{
  imports = [
    ../common/builder.nix
  ];

  system.stateVersion = 5;

  networking.hostName = "cortana";

}
