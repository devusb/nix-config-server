{ pkgs, ... }: {
  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unifi8;
    openFirewall = true;
  };

  services.deploy-backup.backups.unifi = {
    files = [
      ''"$(find "/var/lib/unifi/data/backup/autobackup" -path "*autobackup*unf*" -printf '%Ts\t%p\n' | sort -n | cut -f2 | tail -n 1)"''
    ];
  };

}
