{
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}:
with lib;
{

  # base image
  imports = [
    ../common
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    inputs.nixos-hardware.nixosModules.raspberry-pi-4
    ./fan-control.nix
  ];
  sdImage.compressImage = false;

  # https://github.com/NixOS/nixpkgs/issues/375937
  boot.kernelPackages = pkgs.linuxPackagesFor (
    pkgs.linuxKernel.kernels.linux_rpi4.override {
      ignoreConfigErrors = true;
    }
  );

  services.fstrim.enable = true;

  networking.firewall.enable = false;

  system.stateVersion = "23.05";
  time.timeZone = "America/Chicago";

  environment.systemPackages = with pkgs; [
    libraspberrypi
  ];

}
