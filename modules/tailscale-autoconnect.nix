{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.tailscale-autoconnect;
in
{
  options = {
    services.tailscale-autoconnect = {
      enable = mkEnableOption (mdDoc "Enable Tailscale autoconnection and certificate provisioning");

      extraTailscaleArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = mdDoc "Extra arguments to `tailscale up`";
      };

      tailscaleDomain = mkOption {
        type = types.str;
        default = "springhare-egret.ts.net";
        description = mdDoc "Tailnet domain name";
      };

      issueCerts = mkOption {
        type = types.bool;
        default = true;
        description = mdDoc "Issue TLS certs into /var/lib/tailscale-certs";
      };
    };
  };

  config = mkIf cfg.enable {

    sops.secrets.ts_key = {
      sopsFile = ../tailscale/secrets.yaml;
    };

    services.tailscale.enable = true;
    systemd.services.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";

      # make sure tailscale is running before trying to connect to tailscale
      after = [ "network-pre.target" "tailscaled.service" ];
      wants = [ "network-pre.target" "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];

      # set this service as a oneshot job
      serviceConfig.Type = "oneshot";

      # have the job run this shell script
      script = with pkgs; ''
        # wait for tailscaled to settle
        sleep 2

        # check if we are already authenticated to tailscale
        status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
        if [ $status = "Running" ]; then # if so, then do nothing
          exit 0
        fi

        # otherwise authenticate with tailscale
        ${tailscale}/bin/tailscale up --auth-key file:${config.sops.secrets.ts_key.path} --ssh ${lib.concatStringsSep " " cfg.extraTailscaleArgs}
      '';
    };

    systemd.services.tailscale-cert = mkIf cfg.issueCerts {
      description = "create and renew tailscale certificate";
      requires = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = with pkgs; ''
        mkdir -p /var/lib/tailscale-certs

        # handle first deployment case, wait for tailscale to be ready
        sleep 15

        ${tailscale}/bin/tailscale cert --cert-file=/var/lib/tailscale-certs/tailscale.crt --key-file=/var/lib/tailscale-certs/tailscale.key ${config.networking.hostName}.${cfg.tailscaleDomain}
        ${openssl}/bin/openssl pkcs12 -export -passout pass: -out /var/lib/tailscale-certs/tailscale.p12 -in /var/lib/tailscale-certs/tailscale.crt -inkey /var/lib/tailscale-certs/tailscale.key -certfile /var/lib/tailscale-certs/tailscale.crt
        chmod -R 777 /var/lib/tailscale-certs
      '';
    };

    systemd.timers.tailscale-cert = mkIf cfg.issueCerts {
      description = "create and renew tailscale certificate";
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "1h";
      };
      wantedBy = [ "timers.target" ];
    };

  };
}
