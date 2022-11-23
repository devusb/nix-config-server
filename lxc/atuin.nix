{ lib, pkgs, config, modulesPath, ... }:
let
  backupPath = "/tmp/atuin_db.tar";
in
{

  system.stateVersion = "22.05";

  deployment = {
    targetHost = "192.168.20.102";
    targetPort = 22;
    targetUser = "root";
  };

  networking.hostName = "atuin";

  services.tailscale-autoconnect.enable = true;
  services.tailscale.package = pkgs.tailscale-unstable;

  systemd.services.tailscale-funnel = {
    description = "Enable tailscale funnel";

    after = [ "network-pre.target" "tailscaled.service" ];
    wants = [ "network-pre.target" "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig.Type = "oneshot";

    script = with pkgs; ''
      # handle first deployment case, wait for tailscale to be ready
      sleep 15

      # activate funnel
      funnel_active="$(${tailscale-unstable}/bin/tailscale serve status -json | ${jq}/bin/jq -r 'has("AllowFunnel")')"
      if [ $funnel_active == false ]; then
        ${tailscale-unstable}/bin/tailscale serve funnel on
      fi

      # expose atuin service
      service_active="$(${tailscale-unstable}/bin/tailscale serve status -json | ${jq}/bin/jq -r 'has("Web")')"
      if [ $service_active == false ]; then
        ${tailscale-unstable}/bin/tailscale serve / proxy 8888
      fi
    '';
  };

  services.atuin = {
    enable = true;
    host = "0.0.0.0";
    openRegistration = false;
  };

  services.deployBackup = {
    enable = true;
    name = "atuin";
    files = [
      backupPath
    ];
  };

  services.cron = {
    enable = true;
    systemCronJobs = with pkgs; [
      "0 23 * * 0     root    ${sudo}/bin/sudo -u postgres ${postgresql}/bin/pg_dump -d atuin -F t -f ${backupPath}"
    ];
  };

}
