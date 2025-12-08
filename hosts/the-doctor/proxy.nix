{ config, ... }:
let
  mkAuthentikHost = proxyPass: {
    forceSSL = true;
    enableACME = true;
    acmeRoot = null;

    locations."/" = {
      inherit proxyPass;
      extraConfig = ''
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade_keepalive;

        auth_request     /outpost.goauthentik.io/auth/nginx;
        error_page       401 = @goauthentik_proxy_signin;
        auth_request_set $auth_cookie $upstream_http_set_cookie;
        add_header       Set-Cookie $auth_cookie;

        auth_request_set $authentik_username $upstream_http_x_authentik_username;
        auth_request_set $authentik_groups $upstream_http_x_authentik_groups;
        auth_request_set $authentik_entitlements $upstream_http_x_authentik_entitlements;
        auth_request_set $authentik_email $upstream_http_x_authentik_email;
        auth_request_set $authentik_name $upstream_http_x_authentik_name;
        auth_request_set $authentik_uid $upstream_http_x_authentik_uid;

        proxy_set_header X-authentik-username $authentik_username;
        proxy_set_header X-authentik-groups $authentik_groups;
        proxy_set_header X-authentik-entitlements $authentik_entitlements;
        proxy_set_header X-authentik-email $authentik_email;
        proxy_set_header X-authentik-name $authentik_name;
        proxy_set_header X-authentik-uid $authentik_uid;

        auth_request_set $authentik_auth $upstream_http_authorization;
        proxy_set_header Authorization $authentik_auth;
        proxy_pass_header Authorization;

        proxy_ssl_server_name on;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
      '';
      recommendedProxySettings = false;
    };

    locations."/outpost.goauthentik.io" = {
      proxyPass = "http://127.0.0.1:9000/outpost.goauthentik.io";
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
        add_header Set-Cookie $auth_cookie;
        auth_request_set $auth_cookie $upstream_http_set_cookie;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_ssl_verify off;
      '';
      recommendedProxySettings = false;
    };

    extraConfig = ''
      proxy_buffers 8 16k;
      proxy_buffer_size 32k;

      location @goauthentik_proxy_signin {
        internal;
        add_header Set-Cookie $auth_cookie;
        return 302 /outpost.goauthentik.io/start?rd=$scheme://$http_host$request_uri;
      }
    '';
  };
in
{
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "devusb@devusb.us";
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets.cloudflare.path;
      webroot = null;
    };
  };

  services.nginx = {
    enable = true;
    appendHttpConfig = ''
      map $http_upgrade $connection_upgrade_keepalive {
        default upgrade;
        '''      ''';
      }
      proxy_headers_hash_max_size 512;
      proxy_headers_hash_bucket_size 128;
    '';

    virtualHosts =
      let
        hosts = {
          "radarr.devusb.us" = "https://radarr.chopper.devusb.us";
          "sonarr.devusb.us" = "https://sonarr.chopper.devusb.us";
          "rss.devusb.us" = "https://miniflux.chopper.devusb.us";
        };
      in
      builtins.mapAttrs (_: value: mkAuthentikHost value) hosts;
  };

  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
  };
}
