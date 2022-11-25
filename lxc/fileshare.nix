{ lib, pkgs, config, modulesPath, ... }:
{

  system.stateVersion = "22.05";

  deployment = {
    targetHost = "192.168.20.131";
    targetPort = 22;
    targetUser = "root";
  };

  networking.hostName = "fileshare";

  users = {
    users.mhelton = {
      isNormalUser = true;
      home = "/mnt/homes/mhelton";
      uid = 1101;
    };
    users.ilona = {
      isNormalUser = true;
      home = "/mnt/homes/ilona";
      uid = 1102;
    };
  };

  services.tailscale-autoconnect.enable = true;

  services.promtail = with lib; {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9080;
        grpc_listen_port = 0;
      };
      clients = singleton { url = "http://docker:3100/loki/api/v1/push"; };
      scrape_configs = singleton {
        job_name = "fileshare-journal";
        journal = {
          json = true;
          max_age = "12h";
          path = "/var/log/journal";
          labels = {
            job = "fileshare-journal";
          };
        };
        relabel_configs = singleton {
          source_labels = singleton "__journal__systemd_unit";
          target_label = "unit";
        };
      };
    };
  };

  systemd.services.home-backup = {
    description = "taking home backup";
    serviceConfig.Type = "oneshot";
    script = with pkgs; ''
      cd /mnt/homes/
      ${duplicacy}/bin/duplicacy -log backup -stats -threads 6
    '';
  };

  systemd.timers.home-backup = {
    description = "taking home backup";
    timerConfig = {
      OnCalendar = "*-*-* 02:00:00 America/Chicago";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  systemd.services.vm-backup = {
    description = "taking vm backup";
    serviceConfig.Type = "oneshot";
    script = with pkgs; ''
      cd /mnt/backup/
      ${duplicacy}/bin/duplicacy -log backup -stats -threads 6
      ${duplicacy}/bin/duplicacy prune -keep 0:30 -keep 7:1
    '';
  };

  systemd.timers.vm-backup = {
    description = "taking vm backup";
    timerConfig = {
      OnCalendar = "Mon *-*-* 02:00:00 America/Chicago";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  services.nfs.server = {
    enable = true;
    exports = ''
      /mnt/media 192.168.20.0/24(rw,async,no_subtree_check,no_root_squash,insecure)
      /mnt/backup 192.168.0.0/16(rw,async,no_subtree_check,no_root_squash,insecure)
      /mnt/homes 192.168.20.0/24(rw,async,subtree_check,no_root_squash,crossmnt)
    '';
  };

  services.samba = {
    enable = true;
    securityType = "user";
    extraConfig = ''
      [homes]
      browsable = no
      map archive = yes
      read only = no
    '';
    shares = {
      media = {
        path = "/mnt/media";
        browsable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0777";
        "directory mask" = "0777";
      };
    };
  };

}
