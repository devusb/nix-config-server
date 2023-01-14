{ lib, pkgs, config, modulesPath, ... }:
{

  system.stateVersion = "22.05";

  deployment = {
    targetHost = "192.168.20.105";
    targetPort = 22;
    targetUser = "root";
  };

  networking.hostName = "unifi";

  services.tailscale-autoconnect.enable = true;

  services.deployBackup = {
    enable = true;
    name = "unifi";
    files = [
      ''"$(find "/var/lib/unifi/data/backup/autobackup" -path "*autobackup*unf*" -printf '%Ts\t%p\n' | sort -n | cut -f2 | tail -n 1)"''
    ];
  };

  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unifi6;

    # temporarily add old mongo until unifi controller database upgraded per https://github.com/NixOS/nixpkgs/pull/207382#issuecomment-1371303817
    mongodbPackage = pkgs.stable.mongodb-3_4;
  };
}
