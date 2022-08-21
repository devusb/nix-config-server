{ lib, pkgs, config, modulesPath, ... }:
{

  deployment = {
    targetHost = "192.168.10.1";
    targetPort = 22;
    targetUser = "mhelton";
    # buildOnTarget = true;
  };

  # tailscale
  sops.secrets.ts_key = {
    sopsFile = ../tailscale/secrets.yaml;
  };
  services.tailscale.enable = true;
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = [ "network-pre.target" "tailscale.service" ];
    wants = [ "network-pre.target" "tailscale.service" ];
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
      ${tailscale}/bin/tailscale up --auth-key file:${config.sops.secrets.ts_key.path} --ssh --advertise-exit-node --advertise-routes=192.168.0.0/16 --accept-routes --accept-dns=false
    '';
  };

}
