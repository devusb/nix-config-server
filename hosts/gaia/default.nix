{ lib, pkgs, modulesPath, inputs, ... }:
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

  services.fstrim.enable = true;

  networking.firewall.enable = false;

  system.stateVersion = "23.05";
  time.timeZone = "America/Chicago";

  environment.systemPackages = with pkgs; [
    libraspberrypi
  ];

}
