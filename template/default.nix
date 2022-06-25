{ lib, pkgs, config, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/proxmox-lxc.nix"
  ];

  deployment.buildOnTarget = true;

  system.stateVersion = "22.05";
  services.sshd.enable = true;
  networking.firewall.enable = false;
  time.timeZone = "America/Chicago";
  
  users.users.root.password = "nixos";
  services.openssh.permitRootLogin = lib.mkDefault "yes";
  services.getty.autologinUser = lib.mkDefault "root";

  # required to allow proxmox to set DNS
  networking.resolvconf.enable = false;
  services.resolved.enable = false;

  systemd.suppressedSystemUnits = [
    "sys-kernel-debug.mount"
  ];

  services.syslogd.enable = true;
  
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    autoOptimiseStore = true;
  };

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    vim wget curl logger
  ];

}
