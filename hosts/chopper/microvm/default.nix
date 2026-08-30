{ inputs, ... }:
{
  imports = [
    inputs.microvm.nixosModules.host
  ];

  users.users.microvm.extraGroups = [ "tailscale-key" ];
}
