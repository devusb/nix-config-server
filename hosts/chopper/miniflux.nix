{ pkgs, config, ... }: {
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets.miniflux_creds.path;
    config = {
      LISTEN_ADDR = "0.0.0.0:8080";
      AUTH_PROXY_HEADER = "X-Pomerium-Claim-Email";
    };
  };
}
