{ pkgs, ... }: {
  systemd.services.home-backup = {
    description = "taking home backup";
    serviceConfig.Type = "oneshot";
    script = with pkgs; ''
      cd /r2d2_0/homes/
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
      cd /r2d2_0/backup/
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
      /r2d2_0/media 192.168.0.0/16(rw,async,no_subtree_check,no_root_squash,insecure)
      /r2d2_0/backup 192.168.0.0/16(rw,async,no_subtree_check,no_root_squash,insecure)
      /r2d2_0/homes 192.168.0.0/16(rw,async,subtree_check,no_root_squash,crossmnt)
    '';
  };
  networking.firewall.allowedTCPPorts = [ 2049 ];

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
        path = "/r2d2_0/media";
        browsable = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0777";
        "directory mask" = "0777";
      };
    };
  };

  services.syncthing = {
    enable = true;
    settings = {
      gui.insecureSkipHostcheck = true;
      options.relaysEnabled = false;
      options.globalAnnounceEnabled = false;
      folders = {
        ryujinx = {
          path = "/r2d2_0/homes/mhelton/Sync/ryujinx";
          type = "receiveonly";
          versioning = {
            type = "simple";
            params.keep = "10";
          };
        };
      };
    };
  };

}
