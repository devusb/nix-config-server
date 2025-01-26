{
  pkgs,
  caddyHelpers,
  wildcardDomain,
  ...
}:
{
  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unifi8;
    mongodbPackage = pkgs.mongodb-6_0;
    openFirewall = true;
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "unifi.${wildcardDomain}" = mkHttpsVirtualHost 8443;
  };

  services.deploy-backup.backups.unifi = {
    files = [
      ''"$(find "/var/lib/unifi/data/backup/autobackup" -path "*autobackup*unf*" -printf '%Ts\t%p\n' | sort -n | cut -f2 | tail -n 1)"''
    ];
  };

}
