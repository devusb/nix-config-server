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
      # this doesn't disable completely cleanly right now -- funnel toggles, port changes, caddy will be disabled, but tcp forwarding to 443 will stay on if tailscale enabled after this is disabled
      enable = mkEnableOption (mdDoc "Enable Tailscale serve (via Caddy) for a service");

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

      tailscaleDomain = mkOption {
        type = types.str;
        default = "springhare-egret.ts.net";
        description = mdDoc "Tailnet domain name";
      };

    };
  };

  config = mkIf cfg.enable {

    services.tailscale-autoconnect = {
      enable = true;
      package = cfg.package;
      extraTailscaleArgs = [ "--operator=caddy" ];
      tailscaleDomain = cfg.tailscaleDomain;
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
        service_active="$(${cfg.package}/bin/tailscale serve status -json | ${jq}/bin/jq -r 'has("TCP")')"
        if [ $service_active == false ]; then
          ${cfg.package}/bin/tailscale serve tcp 443
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

    services.caddy = {
      enable = true;
      extraConfig = ''
        ${config.networking.hostName}.${cfg.tailscaleDomain}

        reverse_proxy :${toString cfg.port}
      '';
    };

    systemd.services.tailscaled.after = [ "caddy.service" ];

  };
}
