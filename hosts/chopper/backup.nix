{ pkgs, config, ... }:
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

  systemd.services.upload-home-backup = {
    description = "upload home backup";
    serviceConfig.Type = "oneshot";
    script = with pkgs; ''
      cd /r2d2_0/homes/
      ${duplicacy}/bin/duplicacy -log backup -stats -threads 6
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
      ${duplicacy}/bin/duplicacy prune -keep 1:7 -keep 180:30 -keep 0:360
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
