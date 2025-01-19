{ inputs, ... }:
{
  imports = [
    inputs.microvm.nixosModules.host
  ];

  microvm = {
    vms = {
      kube0.config = import ./vms/kube0.nix;
    };
  };

}
