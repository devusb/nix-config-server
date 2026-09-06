{ inputs, ... }:
{
  imports = [
    inputs.microvm.nixosModules.host
    ./hermes.nix
    ./jellyswarrm.nix
  ];

  users.users.microvm.extraGroups = [ "tailscale-key" ];
}
