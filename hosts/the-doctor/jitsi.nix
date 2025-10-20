{ config, ... }:
let
  hostName = "meet.goon.ventures";
in
{
  services.jitsi-meet = {
    inherit hostName;
    enable = true;
    config = {
      videobridge = {
        health = {
          require-valid-address = false;
        };
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
  };

  sops.secrets.cloudflare = { };
  security.acme = {
    acceptTerms = true;
    defaults.email = "devusb@devusb.us";
    certs = {
      "${hostName}" = {
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets.cloudflare.path;
        webroot = null;
      };
    };
  };
  services.jitsi-videobridge.openFirewall = true;
}
