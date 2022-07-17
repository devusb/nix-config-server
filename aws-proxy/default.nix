{ lib, pkgs, config, modulesPath, ... }:
let pomeriumConfig = pkgs.writeText "config.yaml" (builtins.readFile ./pomerium/config.yaml);
in
{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  # system
  deployment = {
    targetHost = "54.226.127.245";
    targetPort = 22;
    targetUser = "root";
  };
  system.stateVersion = "22.05";

  # networking
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
  };
  networking.hostName = "aws-proxy";
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

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
      ${tailscale}/bin/tailscale up --auth-key file:${config.sops.secrets.ts_key.path} --ssh --accept-routes --advertise-routes=10.0.34.0/23 --advertise-exit-node
    '';
  };

  # pomerium
  sops.secrets.pomerium_secrets = {
    sopsFile = ./secrets.yaml;
  };
   services.pomerium = {
     enable = true;
     configFile = pomeriumConfig;
     secretsFile = config.sops.secrets.pomerium_secrets.path;
   };
   services.redis = {
    enable = true;
   };

}
