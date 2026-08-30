{ inputs, ... }:
{
  imports = [
    inputs.microvm.nixosModules.host
    ./hermes.nix
  ];

  users.users.microvm.extraGroups = [ "tailscale-key" ];
}
