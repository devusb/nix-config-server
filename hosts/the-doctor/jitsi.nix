{ config, ... }:
let
  hostName = "meet.goon.ventures";
in
{
  services.jitsi-meet = {
    inherit hostName;
    enable = true;
    prosody.lockdown = true;
    config = {
      enableWelcomePage = false;
      prejoinPageEnabled = true;
      defaultLang = "en";
    };
    interfaceConfig = {
      SHOW_JITSI_WATERMARK = false;
      SHOW_WATERMARK_FOR_GUESTS = false;
    };
  };

  services.jitsi-videobridge = {
    openFirewall = true;
  };
  systemd.services.jitsi-videobridge2 = {
    after = [ "prosody.service" ];
    requires = [ "prosody.service" ];
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
}
