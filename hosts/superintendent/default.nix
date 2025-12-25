# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../common
    ../common/builder.nix
    ./incus.nix
    inputs.nixos-apple-silicon.nixosModules.default
  ];

  deployment = {
    targetHost = "superintendent";
    targetPort = 22;
    targetUser = "mhelton";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  hardware.asahi.extractPeripheralFirmware = false;

  services.btrfs.autoScrub.enable = true;

  networking.hostName = "superintendent";

  systemd.network.enable = true;
  networking.useNetworkd = true;

  # tailscale
  sops.secrets.ts_key = {
    sopsFile = ../../secrets/default.yaml;
  };
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
    extraUpFlags = [
      "--advertise-exit-node"
      "--ssh"
      "--operator=mhelton"
      "--advertise-tags=tag:server,tag:remote-builder"
    ];
    authKeyFile = config.sops.secrets.ts_key.path;
    authKeyParameters.ephemeral = false;
  };

  time.timeZone = "US/Central";

  system.stateVersion = "25.11"; # Did you read the comment?

}
