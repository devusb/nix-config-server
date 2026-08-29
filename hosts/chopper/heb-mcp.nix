{ config, caddyHelpers, ... }:
{
  services.heb-mcp = {
    enable = true;
    environmentFile = config.sops.secrets.heb_mcp.path;
    settings = {
      PORT = 3001;
      MCP_SERVER_URL = "https://heb-mcp.${caddyHelpers.domain}";
      MCP_AUTH_PROXY_HEADER = "X-authentik-email";
    };
  };

  services.caddy.virtualHosts = with caddyHelpers; {
    "heb-mcp.${domain}" = {
      useACMEHost = domain;
      extraConfig = ''
        handle /outpost.goauthentik.io/* {
          reverse_proxy http://the-doctor:9000
        }

        @human path /authorize* /connect* /api/*
        handle @human {
          forward_auth http://the-doctor:9000 {
            uri /outpost.goauthentik.io/auth/caddy
            copy_headers X-Authentik-Uid X-Authentik-Username X-Authentik-Email
          }
          reverse_proxy :${toString config.services.heb-mcp.settings.PORT}
        }

        handle {
          reverse_proxy :${toString config.services.heb-mcp.settings.PORT}
        }
      '';
    };
  };
}
