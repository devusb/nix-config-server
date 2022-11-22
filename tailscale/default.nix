{ config, pkgs, sops, ... }:
let tailscaleDomain = "springhare-egret.ts.net";
in
{
  sops.secrets.ts_key = {
    sopsFile = ./secrets.yaml;
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
      ${tailscale}/bin/tailscale up --auth-key file:${config.sops.secrets.ts_key.path} --ssh
    '';
  };

  systemd.services.tailscale-cert = {
    description = "create and renew tailscale certificate";
    requires = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = with pkgs; ''
      mkdir -p /var/lib/tailscale-certs
      ${tailscale}/bin/tailscale cert --cert-file=/var/lib/tailscale-certs/tailscale.crt --key-file=/var/lib/tailscale-certs/tailscale.key ${config.networking.hostName}.${tailscaleDomain}
      ${openssl}/bin/openssl pkcs12 -export -passout pass:"tailscale" -out /var/lib/tailscale-certs/tailscale.p12 -in /var/lib/tailscale-certs/tailscale.crt -inkey /var/lib/tailscale-certs/tailscale.key -certfile /var/lib/tailscale-certs/tailscale.crt
      chmod -R 777 /var/lib/tailscale-certs
    '';
  };

  systemd.timers.tailscale-cert = {
    description = "create and renew tailscale certificate";
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1h";
    };
    wantedBy = [ "timers.target" ];
  };
}
