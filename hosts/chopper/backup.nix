{
  pkgs,
  config,
  caddyHelpers,
  ...
}:
{
  users.groups.backup = {
    gid = 1003;
  };
  services.go-simple-upload-server = {
    enable = true;
    settings = {
      token = "59af2e561fc9f80a9bb9";
      addr = "127.0.0.1:8081";
      max_upload_size = 1073741824;
      document_root = "/r2d2_0/backup/config";
    };
    group = config.users.groups.backup.name;
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "backup.${domain}" = helpers.mkVirtualHost 8081;
  };

  systemd.services.upload-home-backup = {
    description = "upload home backup";
    serviceConfig.Type = "oneshot";
    script = with pkgs; ''
      cd /r2d2_0/homes/
      ${duplicacy}/bin/duplicacy -log backup -stats -threads 6
      ${duplicacy}/bin/duplicacy prune -keep 30:360 -keep 7:30
    '';
  };

  systemd.timers.upload-home-backup = {
    description = "upload home backup";
    timerConfig = {
      OnCalendar = "*-*-* 02:00:00 America/Chicago";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  systemd.services.upload-config-backup = {
    description = "upload config backup";
    serviceConfig.Type = "oneshot";
    script = with pkgs; ''
      cd /r2d2_0/backup/
      ${duplicacy}/bin/duplicacy -log backup -stats -threads 6
      ${duplicacy}/bin/duplicacy prune -keep 0:360 -keep 90:30 -keep 7:1
    '';
  };

  systemd.timers.upload-config-backup = {
    description = "upload config backup";
    timerConfig = {
      OnCalendar = "Mon *-*-* 02:00:00 America/Chicago";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  services.deploy-backup.enable = true;

}
