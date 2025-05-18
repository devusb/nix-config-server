{ config, ... }:
{
  sops.secrets.coturn_auth_secret = {
    owner = "turnserver";
  };

  services.coturn = {
    enable = true;
    static-auth-secret-file = config.sops.secrets.coturn_auth_secret.path;
    extraConfig = ''
      fingerprint
      stale-nonce
      no-multicast-peers
      total-quota=0
      bps-capacity=0
    '';
  };

  networking.firewall = {
    allowedTCPPortRanges = [
      {
        from = 3478;
        to = 3479;
      }
    ];
    allowedUDPPortRanges = [
      {
        from = 3478;
        to = 3479;
      }
      {
        from = 49152;
        to = 65535;
      }
    ];
  };
}
