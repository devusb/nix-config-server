{ inputs, ... }:
{
  imports = [
    inputs.microvm.nixosModules.host
    ./echoip.nix
  ];

  users.users.microvm.extraGroups = [ "tailscale-key" ];
}
