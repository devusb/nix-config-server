{ config, pkgs, lib, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
    ];

  deployment = {
    targetHost = "spdr";
    targetPort = 22;
    targetUser = "mhelton";
    buildOnTarget = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 5;

  # zfs
  boot.supportedFilesystems = [ "zfs" ];
  networking.hostId = "9141a4f1";
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

  # erase your darlings
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r rpool/local/root@blank
  '';
  environment.etc = {
    nixos.source = "/persist/etc/nixos";
    NIXOS.source = "/persist/etc/NIXOS";
    machine-id.source = "/persist/etc/machine-id";
  };

  # networking
  networking.hostName = "spdr";
  networking.networkmanager.enable = true;
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  system.stateVersion = "23.05";

  time.timeZone = "US/Eastern";

  # tailscale
  services.tailscale-autoconnect = {
    enable = true;
    extraTailscaleArgs = [ "--advertise-exit-node" "--accept-routes" ];
  };
  systemd.services.tailscaled.serviceConfig.BindPaths = "/persist/var/lib/tailscale:/var/lib/tailscale";

  users.users.mhelton = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC5rmy7r//z1fARqDe6sIu5D4Nt5uD3rRvwtADDgb+sS6slv6I51Gm2rKcxDIHgYBSyhTDIuhNHlnn+cyJK4ZPxyZFxF0Vy0fZIFG3Y7AqkyQ0oXEDGYyqfL8U0mi0uGKmVW02T45w16REJG3x77uncw8VVxdEpKuYw+wk7uRlQpP/UiFYWsX4NS9rUS/aZrYZ2ys1/dCPqvz4KPXk7SZrqyqkiumIr8O0wluYI5FwhMtd3xpD9AQVI3V0zjYZPwesL+BkW4CAAm5dSnsns3haAuWHti/QLSR+90k15KhflXlq6JDzE4jrMbd1DYZqoVuTgoZxDB3HDJwEwpbYCWKLFaGR6ZDhE3NeFikNkdDRrlIcrK1wJCEO2QuDZ43IE/bDhLhOmqfliL6kRr+2G1AvY4Hr0jnJHbbHqN9mES5+VJZuhH2ii+QHS70VZN0NNQv7f0QJqiTVcUVuPXksBp6oojbkXK79CWd1X0u3shd6XinZ5N3KAD4PT8zlTCmglXNYamc1JpRqKzgFwgFcljXpHwtfuezpNVmzo1Vqi6Ib9S8qJi9rahhsafYP3Y+8EV3Ii3oXmGQBSwumAHCQIkiQ/Sc+FRS02GRgWuYOaQfvW99kLXbX+0eCMSdCJSLC+H1cO2b451qpDGGDnH9w+EvS04oyv4yufpwFlhys7qfU6HQ== mhelton@gmail.com" ];
  };
  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/persist/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = "/persist/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    micro
    htop
  ];

  # monitoring
  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = [ "systemd" "ethtool" "netstat" ];
    };
  };

  services.plex = {
    enable = true;
    dataDir = "/persist/var/lib/plex";
    openFirewall = true;
    package = pkgs.plexpass;
  };

}

