{ domain, ... }:
{
  inherit domain;
  helpers = {
    mkVirtualHost = port: {
      useACMEHost = domain;
      extraConfig = ''
        reverse_proxy :${toString port}
      '';
    };
    mkHttpsVirtualHost = port: {
      useACMEHost = domain;
      extraConfig = ''
        reverse_proxy localhost:${toString port} {
            transport http {
                    tls
                    tls_insecure_skip_verify
            }
        }
      '';
    };
    mkSocketVirtualHost = path: {
      useACMEHost = domain;
      extraConfig = ''
        reverse_proxy unix/${path}
      '';
    };
  };

}
