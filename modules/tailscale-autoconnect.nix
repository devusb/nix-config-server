{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.tailscale-autoconnect;
in
{
  options = {
    services.tailscale-autoconnect = {
      enable = mkEnableOption (mdDoc "Enable Tailscale autoconnection and certificate provisioning");

      package = mkPackageOption pkgs "tailscale" { };

      extraTailscaleArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = mdDoc "Extra arguments to `tailscale up`";
      };

      authKeyFile = mkOption {
        type = types.path;
        example = "/run/secrets/tailscale_key";
      };
    };
  };

  config = mkIf cfg.enable {

    services.tailscale = {
      enable = true;
      package = cfg.package;
    };

    systemd.services.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";

      # set this service as a oneshot job
      serviceConfig.Type = "oneshot";

      # have the job run this shell script
      script = with pkgs; ''
        # check if we are already authenticated to tailscale
        status="$(${cfg.package}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
        if [ $status = "Running" ]; then # if so, then do nothing
          exit 0
        fi

        # otherwise authenticate with tailscale
        ${cfg.package}/bin/tailscale up --auth-key file:${cfg.authKeyFile} --ssh ${lib.concatStringsSep " " cfg.extraTailscaleArgs}
      '';
    };

    systemd.timers.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";
      timerConfig = {
        OnActiveSec = "15s";
      };
      wantedBy = [ "timers.target" ];
    };

  };
}
