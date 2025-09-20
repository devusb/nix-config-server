{
  pkgs,
  caddyHelpers,
  ...
}:
{
  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unifi;
    mongodbPackage = pkgs.mongodb-7_0;
    openFirewall = true;
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "unifi.${domain}" = helpers.mkHttpsVirtualHost 8443;
  };

  services.deploy-backup.backups.unifi = {
    files = [
      ''"$(find "/var/lib/unifi/data/backup/autobackup" -path "*autobackup*unf*" -printf '%Ts\t%p\n' | sort -n | cut -f2 | tail -n 1)"''
    ];
  };

}
