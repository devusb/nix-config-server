{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.tailscale-serve;
in
{
  imports = [
    ./tailscale-autoconnect.nix
  ];

  options = {
    services.tailscale-serve = {
      # this doesn't disable cleanly right now -- enable will turn serve on, funnel toggle works while enabled, changing port works, but can't actually disable serve with this
      enable = mkEnableOption (mdDoc "Enable Tailscale serve for a service");

      package = mkPackageOption pkgs "tailscale" { };

      funnel = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Enable Tailscale Funnel";
      };

      port = mkOption {
        type = types.ints.u16;
        default = 80;
        description = mdDoc "Port for tailscale to direct traffic to (i.e. the upstream service)";
      };

    };
  };

  config = mkIf cfg.enable {

    services.tailscale-autoconnect = {
      enable = true;
      package = cfg.package;
    };

    systemd.services.tailscale-serve = {
      description = "Enable Tailscale serve";

      after = [ "network-pre.target" "tailscaled.service" ];
      wants = [ "network-pre.target" "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig.Type = "oneshot";

      script = with pkgs; ''
        # handle first deployment case, wait for tailscale to be ready
        sleep 15

        # expose service
        service_active="$(${cfg.package}/bin/tailscale serve status -json | ${jq}/bin/jq -r 'has("Web")')"
        if [ $service_active == true ]; then
          url="$(${cfg.package}/bin/tailscale serve status -json | ${jq}/bin/jq -r '.Web[][][].Proxy')"
          if ! [[ $url =~ ${toString cfg.port} ]]; then
            ${cfg.package}/bin/tailscale serve --remove /
            ${cfg.package}/bin/tailscale serve / proxy ${toString cfg.port}
          fi
        else
          ${cfg.package}/bin/tailscale serve / proxy ${toString cfg.port}
        fi
      '' + (if cfg.funnel then ''
        # activate funnel
        funnel_active="$(${cfg.package}/bin/tailscale serve status -json | ${jq}/bin/jq -r 'has("AllowFunnel")')"
        if [ $funnel_active == false ]; then
          ${cfg.package}/bin/tailscale serve funnel on
        fi
      '' else ''
        ${cfg.package}/bin/tailscale serve funnel off
      '');
    };

  };
}
