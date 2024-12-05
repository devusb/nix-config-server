{
  config,
  pkgs,
  lib,
  ...
}:

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

      authKeyFile = mkOption {
        type = types.path;
        example = "/run/secrets/tailscale_key";
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
      authKeyFile = cfg.authKeyFile;
    };

    systemd.services.tailscale-serve = {
      description = "Enable Tailscale serve";

      serviceConfig.Type = "oneshot";

      script =
        with pkgs;
        ''
          # handle first deployment case, wait for tailscale to be ready
          sleep 15
          service_active="$(${cfg.package}/bin/tailscale serve status -json | ${jq}/bin/jq -r 'has("TCP")')"
          funnel_active="$(${cfg.package}/bin/tailscale funnel status -json | ${jq}/bin/jq -r 'has("AllowFunnel")')"
        ''
        + (
          if !cfg.funnel then
            ''
              # deactivate funnel if it is currently active
              # expose service if not active
              if [[ $service_active == false || $funnel_active == true ]]; then
                ${cfg.package}/bin/tailscale serve --bg --yes --tcp 443 443
              fi
            ''
          else
            ''
              # if currently serving but not funneling
              # if not funneling and not serving
              if [[ ($service_active == true && $funnel_active == false) || $service_active == false ]]; then
                ${cfg.package}/bin/tailscale funnel --bg --yes --tcp 443 443
              fi
            ''
        );
    };

    systemd.timers.tailscale-serve = {
      description = "Automatic connection to Tailscale";
      timerConfig = {
        OnActiveSec = "20s";
      };
      wantedBy = [ "timers.target" ];
    };

    services.caddy = {
      enable = true;
      extraConfig = ''
        ${config.networking.hostName}.${cfg.tailscaleDomain}

        reverse_proxy :${toString cfg.port}
      '';
    };

    systemd.services.tailscaled.wants = [ "caddy.service" ];
    systemd.services.tailscaled.after = [ "caddy.service" ];

  };
}
