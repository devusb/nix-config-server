{
  inputs,
  config,
  pkgs,
  ...
}:
let
  authHost = "auth.devusb.us";
in
{
  imports = [
    inputs.authentik-nix.nixosModules.default
  ];

  networking.firewall = {
    allowedTCPPorts = [ 443 ];
  };

  sops.secrets.authentik = { };
  services.authentik = {
    enable = true;
    environmentFile = config.sops.secrets.authentik.path;
    nginx = {
      enable = true;
      enableACME = true;
      host = authHost;
    };
  };
  services.nginx.virtualHosts."${authHost}".extraConfig = ''
    ssl_verify_client on;
    ssl_client_certificate ${
      pkgs.fetchurl {
        url = "https://developers.cloudflare.com/ssl/static/authenticated_origin_pull_ca.pem";
        hash = "sha256-wU/tDOUhDbBxn+oR0fELM3UNwX1gmur0fHXp7/DXuEM";
      }
    };
  '';

  sops.secrets.cloudflare = { };
  security.acme = {
    acceptTerms = true;
    defaults.email = "devusb@devusb.us";
    certs = {
      "${authHost}" = {
        dnsProvider = "cloudflare";
        environmentFile = config.sops.secrets.cloudflare.path;
        webroot = null;
      };
    };
  };

}
